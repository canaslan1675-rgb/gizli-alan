#!/usr/bin/env bash
# Checks a test APK against the known-good test13 reference. Exits non-zero
# on any failure. Usage: scripts/verify_test_apk.sh <apk> [reference.apk]
set -uo pipefail
APK=${1:?apk}; REF=${2:-}
cd "$(dirname "$0")/.."
BT=$(ls -d "${ANDROID_HOME:-/workspace/tools/android/sdk}"/build-tools/* | sort -V | tail -1)
export PATH="${JAVA_HOME:-/workspace/tools/android/jdk}/bin:$PATH"
fail=0; ok(){ echo "OK   $*"; }; bad(){ echo "FAIL $*"; fail=1; }
B=$("$BT/aapt" dump badging "$APK")
grep -q "package: name='com.offerforge.gizlialan'" <<<"$B" && ok package || bad package
VC=$(sed -n "s/.*versionCode='\([0-9]*\)'.*/\1/p" <<<"$B" | head -1); [ "${VC:-0}" -ge 45 ] && ok "versionCode $VC" || bad "versionCode $VC"
X=$("$BT/aapt" dump xmltree "$APK" AndroidManifest.xml); grep -q ProfileAdminReceiver <<<"$X" && ok "ProfileAdminReceiver (İkinci telefon)" || bad "ProfileAdminReceiver missing"
L=$(unzip -l "$APK" | awk '{print $4}')
for abi in arm64-v8a x86_64; do grep -q "lib/$abi/libapp.so" <<<"$L" && ok "ABI $abi" || bad "ABI $abi missing"; done
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
unzip -q "$APK" lib/arm64-v8a/libapp.so -d "$T"
for s in sp_setup spSetUp gizlialan/second_phone; do grep -q -a "$s" "$T/lib/arm64-v8a/libapp.so" && ok "dart: $s" || bad "dart: $s missing"; done
grep -q -a "Shelter/Island" "$T/lib/arm64-v8a/libapp.so" && bad "third-party app names present" || ok "no Shelter/Island text"
if [ -f .firebase.env ]; then
  set -a; . ./.firebase.env; set +a
  grep -q -a -F "$JOI_APPCHECK_DEBUG_TOKEN" "$T/lib/arm64-v8a/libapp.so" && ok "App Check debug token compiled in" || bad "debug token missing"
  grep -q -a -F "$FIREBASE_API_KEY" "$T/lib/arm64-v8a/libapp.so" && ok "FIREBASE_* defines" || bad "FIREBASE defines missing"
fi
C=$("$BT/apksigner" verify --print-certs "$APK" 2>/dev/null | sed -n 's/.*Signer #1 certificate SHA-256 digest: //p')
U=$(openssl x509 -in /workspace/secrets/upload_certificate.pem -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2 | tr -d : | tr A-F a-f)
[ -n "$C" ] && [ "$C" = "$U" ] && ok "signed with upload key" || bad "signature != upload cert"
if [ -n "$REF" ]; then
  s1=$(stat -c%s "$APK"); s0=$(stat -c%s "$REF")
  awk -v a=$s1 -v b=$s0 'BEGIN{d=(a-b)/b; if(d<0)d=-d; exit !(d<=0.10)}' && ok "size $s1 vs ref $s0 (≤10%)" || bad "size $s1 vs ref $s0 (>10%)"
  R=$(unzip -l "$REF" | awk '{print $4}' | grep -v '^$' | sort); N=$(sort <<<"$L" | grep -v '^$')
  M=$(comm -23 <(echo "$R") <(echo "$N")); [ -z "$M" ] && ok "no files missing vs ref" || { bad "files missing vs ref:"; echo "$M"; }
fi
[ $fail = 0 ] && echo "ALL CHECKS PASSED" || echo "CHECKS FAILED"; exit $fail
