#!/usr/bin/env bash
# Builds the GizliAlan PLAY release AAB (full flavor = İkinci telefon,
# PRO_STUB=false, NO App Check debug token) WITH the Joi online config.
# 0.6.3+48 was built without FIREBASE_* -> online Joi was unavailable on Play.
# This script refuses to build without them and verifies they are compiled in.
# Usage: scripts/build_release_aab.sh /path/out.aab   (never prints secrets)
set -euo pipefail
DEST=${1:?usage: build_release_aab.sh <out.aab>}
cd "$(dirname "$0")/.."
: "${FLUTTER:=/workspace/tools/flutter/bin/flutter}"
export JAVA_HOME=${JAVA_HOME:-/workspace/tools/android/jdk}
export ANDROID_HOME=${ANDROID_HOME:-/workspace/tools/android/sdk}
[ -f .firebase.env ] || { echo "missing .firebase.env" >&2; exit 1; }
[ -f android/key.properties ] || { echo "missing android/key.properties (upload key)" >&2; exit 1; }
set -a; . ./.firebase.env; set +a
# 0.6.5: re-inject the approved measurement keys (AppMetrica + TikTok, Data
# safety approved 0.6.1) — 0.6.3/0.6.4 were built without them. Files only.
EXTRA=()
SEC=${SECRETS_DIR:-/home/box/.secrets}
if [ -s "$SEC/appmetrica_gizlialan_api_key" ]; then APPMETRICA_API_KEY=$(tr -d '\n' < "$SEC/appmetrica_gizlialan_api_key"); EXTRA+=(--dart-define=APPMETRICA_API_KEY="$APPMETRICA_API_KEY"); else APPMETRICA_API_KEY=__none_am__; echo "WARN: no AppMetrica key" >&2; fi
if [ -s "$SEC/tiktok_gizlialan_app_secret" ]; then TIKTOK_APP_SECRET=$(tr -d '\n' < "$SEC/tiktok_gizlialan_app_secret"); EXTRA+=(--dart-define=TIKTOK_APP_SECRET="$TIKTOK_APP_SECRET"); else TIKTOK_APP_SECRET=__none_tt__; echo "WARN: no TikTok secret" >&2; fi
for v in FIREBASE_PROJECT_ID FIREBASE_APP_ID FIREBASE_API_KEY; do
  [ -n "${!v:-}" ] || { echo "missing $v in .firebase.env" >&2; exit 1; }
done
"$FLUTTER" build appbundle --release --flavor full \
  --dart-define=FLAVOR=full \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
  --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" "${EXTRA[@]}" 2>&1 \
  | grep -v -F -e "$FIREBASE_API_KEY" -e "$APPMETRICA_API_KEY" -e "$TIKTOK_APP_SECRET"
SRC=build/app/outputs/bundle/fullRelease/app-full-release.aab
TMP=$(mktemp -d)
unzip -q -o "$SRC" base/lib/arm64-v8a/libapp.so -d "$TMP"
for v in FIREBASE_PROJECT_ID FIREBASE_APP_ID FIREBASE_API_KEY; do
  grep -q -F "${!v}" "$TMP/base/lib/arm64-v8a/libapp.so" \
    || { echo "AAB is missing $v (online Joi would be off)" >&2; exit 1; }
done
if grep -q -F "${JOI_APPCHECK_DEBUG_TOKEN:-__none__}" "$TMP/base/lib/arm64-v8a/libapp.so"; then
  echo "AAB contains the App Check DEBUG token - refusing" >&2; exit 1
fi
rm -rf "$TMP"
mkdir -p "$(dirname "$DEST")"
cp "$SRC" "$DEST"
echo "AAB: $DEST (Joi online config verified)"
