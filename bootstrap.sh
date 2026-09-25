#!/usr/bin/env bash
# Helper for fresh machines: fetch deps, and re-create android/ only if it is
# missing (it is committed in the repo, including FLAG_SECURE MainActivity and
# the minimal-permission manifest — don't overwrite it).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  if [[ -x /workspace/tools/flutter/bin/flutter ]]; then
    export PATH=/workspace/tools/flutter/bin:$PATH
  else
    echo "ERROR: flutter not found. Install: git clone -b stable https://github.com/flutter/flutter.git"
    exit 1
  fi
fi

if [[ ! -f android/app/build.gradle.kts ]]; then
  echo "==> android/ missing — generating (remember to re-apply FLAG_SECURE/manifest changes!)"
  flutter create --org com.offerforge --project-name gizlialan --platforms=android .
fi

flutter pub get
flutter analyze
flutter test
echo "DONE. Run: flutter run   |   Release: flutter build apk --release"
