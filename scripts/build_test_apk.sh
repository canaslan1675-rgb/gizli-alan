#!/usr/bin/env bash
# Builds a GizliAlan side-load TEST APK exactly like the reference test13
# (full flavor = İkinci telefon, arm64-v8a + x86_64 like CI, PRO_STUB, App
# Check debug token + FIREBASE_* from the gitignored .firebase.env).
# NEVER upload the result to Play. Usage: scripts/build_test_apk.sh test16
set -euo pipefail
LABEL=${1:?usage: build_test_apk.sh <testN>}
cd "$(dirname "$0")/.."
: "${FLUTTER:=/workspace/tools/flutter/bin/flutter}"
export JAVA_HOME=${JAVA_HOME:-/workspace/tools/android/jdk}
export ANDROID_HOME=${ANDROID_HOME:-/workspace/tools/android/sdk}
[ -f .firebase.env ] || { echo "missing .firebase.env" >&2; exit 1; }
[ -f android/key.properties ] || { echo "missing android/key.properties (upload key)" >&2; exit 1; }
set -a; . ./.firebase.env; set +a
for v in FIREBASE_PROJECT_ID FIREBASE_APP_ID FIREBASE_API_KEY JOI_APPCHECK_DEBUG_TOKEN; do
  [ -n "${!v:-}" ] || { echo "missing $v in .firebase.env" >&2; exit 1; }
done
VER=$(sed -n 's/^version: //p' pubspec.yaml)
OUT=${OUT_DIR:-/workspace/gizlialan-test-builds}
mkdir -p "$OUT"
"$FLUTTER" build apk --release --flavor full \
  --target-platform android-arm64,android-x64 \
  --dart-define=FLAVOR=full \
  --dart-define=PRO_STUB=true \
  --dart-define=JOI_APPCHECK_DEBUG_TOKEN="$JOI_APPCHECK_DEBUG_TOKEN" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
  --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" 2>&1 \
  | grep -v -F -e "$JOI_APPCHECK_DEBUG_TOKEN" -e "$FIREBASE_API_KEY"
DEST="$OUT/GizliAlan-${VER/+/-}-full-$LABEL.apk"
cp build/app/outputs/flutter-apk/app-full-release.apk "$DEST"
echo "APK: $DEST"
"$(dirname "$0")/verify_test_apk.sh" "$DEST"
