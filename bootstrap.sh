#!/usr/bin/env bash
# Bootstrap Android/iOS platform folders while preserving hand-written lib/ + pubspec.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: flutter not found in PATH."
  echo "Install Flutter: https://docs.flutter.dev/get-started/install"
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Creating temp Flutter project (org: com.offerforge, name: gizlialan)..."
flutter create \
  --org com.offerforge \
  --project-name gizlialan \
  --platforms=android \
  "$TMP/gizlialan"

# Preserve our sources
echo "==> Merging platform folders into $ROOT ..."
# Copy android/ if missing or incomplete
if [[ ! -f "$ROOT/android/app/build.gradle" && ! -f "$ROOT/android/app/build.gradle.kts" ]]; then
  rm -rf "$ROOT/android"
  cp -a "$TMP/gizlialan/android" "$ROOT/android"
else
  echo "    android/ already present — keeping yours (check applicationId)."
fi

# Ensure applicationId
MANIFEST="$ROOT/android/app/src/main/AndroidManifest.xml"
if [[ -f "$MANIFEST" ]]; then
  echo "    AndroidManifest present."
fi

# Copy analysis / test scaffolding if useful
[[ -d "$ROOT/test" ]] || mkdir -p "$ROOT/test"
if [[ ! -f "$ROOT/test/widget_test.dart" ]]; then
  cat > "$ROOT/test/widget_test.dart" <<'TEST'
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () {
    expect(1 + 1, 2);
  });
}
TEST
fi

echo "==> flutter pub get"
flutter pub get

echo ""
echo "DONE. Run: flutter run"
echo "Package expected: com.offerforge.gizlialan"
echo "If applicationId differs, edit android/app/build.gradle(.kts)"
