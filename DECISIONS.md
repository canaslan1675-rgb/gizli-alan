# Decisions log

| Date (TR) | Decision | Why |
|-----------|----------|-----|
| 2026-09-25 | Architecture = research option C + E: in-app encrypted vault + dual-mode (calculator) UI. No Work Profile, launcher role, app cloning or cloud. | MVP scope per research §6 / brief §1. |
| 2026-09-25 | Encryption always on (removed scaffold's "hide-only" default). AES-256-GCM via `cryptography` (+ `cryptography_flutter` native on Android) instead of pointycastle/`encrypt`. | Pure-Dart pointycastle GCM took ~6 s per 5 MB; `cryptography` Dart impl ~0.6 s and native on device. GCM gives integrity too. |
| 2026-09-25 | One random 256-bit data key per space in Keystore-backed secure storage; not wrapped by PIN. | Allows biometric unlock without PIN; PIN change needs no re-encryption. Limitation documented in PRIVACY/README. Future: biometric-bound Keystore key + PIN-wrapped DEK. |
| 2026-09-25 | PIN = 4–8 digits, PBKDF2-HMAC-SHA256 120k iterations on an isolate; lockout after 5 fails (30 s doubling, cap 15 min). Calculator `=` checks don't count as failures. | Calculator users type normal numbers; counting them would lock the owner out. |
| 2026-09-25 | Decoy PIN opens a separate `decoy` space with its own key; biometrics always open the real space; decoy settings hide security options. | Keepsafe-style decoy, disclosed in listing. |
| 2026-09-25 | Calculator entry on by default in onboarding, with explicit disclosure screen + toggle; launcher label stays "GizliAlan"; ⓘ in calculator explains the entry. Removed scaffold's "4× =" / hidden second-launcher ideas. | Play Deceptive Behavior: listing = behaviour, no cloaking. |
| 2026-09-25 | Removed dart-define `DIRECT_VAULT` second-launcher stub; direct entry = turn calculator off. | Stub never worked per-activity; fewer launcher tricks = lower review risk. |
| 2026-09-25 | Imports via system Photo Picker (`image_picker`) and SAF (`file_picker`), export via SAF "save as"; manifest removes all storage/media/camera/mic permissions. | Minimal permissions; no plaintext temp copy by us (image_picker cache copy is deleted after import). |
| 2026-09-25 | Originals are **not** deleted from the phone gallery after import (user is told). | Deleting needs MediaStore write requests; out of MVP scope. |
| 2026-09-25 | FLAG_SECURE always on (not a toggle). allowBackup=false + data-extraction rules exclude everything. | Keys can't be backed up anyway; backups would be useless blobs. |
| 2026-09-25 | minSdk 28. | BiometricPrompt + FragmentActivity without AppCompat theme issues on ≤8. |
| 2026-09-25 | No billing/IAP code in v1; brief pricing (Free 30–50 items, Pro 249 TL one-time / 449 TL yearly) deferred to a UI stub later. | Brief: real payment integration is a BLOCKER-level step. |
| 2026-09-25 | Language via simple map l10n + `L10nScope` InheritedWidget (no gen-l10n). | Keeps scaffold approach, rebuilds open screens on change. |
