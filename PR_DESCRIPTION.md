# feat: GizliAlan MVP v1 — encrypted "hidden virtual phone" vault

## Summary
Turns the scaffold into a working MVP of the personal vault (device owner only),
following research §6 and the project brief. All vault content is now
**always encrypted** (AES-256-GCM); the app opens as an optional, **openly
disclosed** real calculator where `PIN` + `=` opens the vault; PIN + biometric
unlock with lockout and auto-lock; FLAG_SECURE; encrypted gallery, files and
notes; a virtual-phone home grid; optional decoy PIN with a separate empty
vault; TR/EN.

No spyware/monitoring features: no SMS/calls/contacts/location, no
Accessibility, no Device Admin, no notification listener, no network (release
APK has no INTERNET permission), no icon hiding/cloaking.

## What's implemented
- **Crypto/auth core:** AES-256-GCM (native on Android via `cryptography_flutter`), per-space 256-bit data keys in Keystore-backed `flutter_secure_storage` (`resetOnError: false`), PBKDF2-HMAC-SHA256 PIN hashes (120k it., isolate), 4–8 digit PIN, lockout after 5 wrong PINs (30 s doubling, cap 15 min), decoy PIN, legacy scaffold hash migration.
- **Storage:** encrypted notes document, encrypted gallery/files collections with an encrypted index (no file names on disk), atomic writes, LRU decrypt cache, migration of scaffold plaintext notes/files.
- **Entry:** real calculator (precedence, %, backspace) + PIN`=` vault entry, long-press `=` for biometrics, ⓘ disclosure dialog; or PIN pad when calculator entry is off.
- **Onboarding (3 steps):** own-device confirmation, calculator disclosure + toggle, PIN with "no recovery" warning, TR/EN switch.
- **Vault:** virtual-phone home (clock, icon grid, dock, wallpapers); gallery (Photo Picker import, grid, pinch-zoom viewer, SAF export, delete); files (SAF import, view images, export, delete); notes (create/edit/delete/search); settings (change PIN, biometrics, decoy PIN, auto-lock, entry mode, language, wallpaper, privacy info, full reset). Decoy vault shows only neutral settings.
- **Platform:** Android project committed; `FlutterFragmentActivity` + FLAG_SECURE; manifest with only `USE_BIOMETRIC`, storage/media/camera/mic removed; `allowBackup=false` + data-extraction rules; minSdk 28.
- **Auto-lock:** on background (immediately or 15 s / 1 min / 5 min), guarded while system pickers/biometric prompt are open; lock closes the session and pops to the entry screen.

## Changed / added files
| File | Summary |
|------|---------|
| `pubspec.yaml`, `pubspec.lock` | Updated deps (secure_storage 11, local_auth 3, image_picker, file_picker 13, cryptography(+_flutter)); dropped `encrypt` |
| `analysis_options.yaml` | Exclude build/android from analysis |
| `lib/main.dart` | Bootstrap services, date formatting, compliance notes |
| `lib/app.dart` | Session ownership, enter/lock vault, biometric unlock, auto-lock with picker guard, full reset |
| `lib/theme.dart` | `CardThemeData` fix, wallpaper gradients |
| `lib/l10n/l10n.dart` | Fallback lookup + `L10nScope` for live language switching |
| `lib/l10n/en.dart`, `lib/l10n/tr.dart` | Full TR/EN strings for all new screens and disclosures |
| `lib/models/note.dart` | Formatting only |
| `lib/services/crypto_service.dart` | **New** AES-256-GCM seal/open + PBKDF2 |
| `lib/services/secure_kv.dart` | **New** secure storage abstraction (Keystore / memory) |
| `lib/services/auth_service.dart` | Rewritten: PBKDF2 PIN, decoy PIN, lockout, data keys, legacy migration |
| `lib/services/biometric_service.dart` | **New** local_auth wrapper |
| `lib/services/vault_space.dart` | **New** real/decoy enum |
| `lib/services/vault_session.dart` | **New** unlocked-space container + encrypted file IO |
| `lib/services/vault_storage.dart` | Rewritten: encrypted collections with encrypted index |
| `lib/services/notes_repository.dart` | Rewritten: encrypted notes |
| `lib/services/calculator_engine.dart` | **New** pure calculator + PIN candidate |
| `lib/services/legacy_migration.dart` | **New** scaffold plaintext → encrypted |
| `lib/services/settings_service.dart` | Calculator entry, biometrics, auto-lock, language, wallpaper (encryption toggle removed) |
| `lib/screens/decoy_calculator_screen.dart` | Rewritten: real calculator + disclosed PIN`=` entry |
| `lib/screens/pin_lock_screen.dart` | Rewritten: lockout countdown, biometrics, real/decoy routing |
| `lib/screens/onboarding_screen.dart` | Rewritten: 3-step flow with disclosures |
| `lib/screens/vault_home_screen.dart` | Rewritten: virtual-phone home grid |
| `lib/screens/gallery_screen.dart` | **New** encrypted gallery grid + import |
| `lib/screens/photo_viewer_screen.dart` | **New** viewer with export/delete |
| `lib/screens/files_screen.dart` | Rewritten: encrypted files |
| `lib/screens/notes_list_screen.dart`, `note_edit_screen.dart` | Encrypted notes, search, no empty notes |
| `lib/screens/settings_screen.dart` | **New** settings (was referenced but missing) |
| `lib/screens/set_pin_screen.dart` | **New** change PIN / set decoy PIN |
| `lib/widgets/vault_actions.dart` | **New** export/delete helpers, progress dialog |
| `android/**` | **New** platform project: FLAG_SECURE MainActivity, minimal manifest, backup rules, minSdk 28 |
| `test/*.dart` | **New** crypto, auth, calculator, storage unit tests + app-flow widget test |
| `PRIVACY.md` | Rewritten to match actual behaviour |
| `docs/PLAY_COMPLIANCE.md` | **New** permissions, Data safety answers, TR/EN listing, reviewer notes |
| `README.md`, `bootstrap.sh` | Updated for new architecture / tooling |
| `DECISIONS.md`, `PROGRESS.md`, `BLOCKERS.md`, `AUTONOMOUS_BRIEF.md` | Project management docs |

## Verification
- `flutter analyze` → **No issues found** (Flutter 3.47.5 stable, Dart 3.13.4)
- `flutter test` → **34 passed** (crypto 11, auth 11, calculator 6, storage 5, app flow 1)
- `flutter build apk --release` → **built** (54.6 MB universal, debug-signed); `aapt2 dump permissions` → only `USE_BIOMETRIC` (+ AndroidX-internal signature permission), **no INTERNET**
- Not yet tested on a physical device/emulator.

## Remaining / next
- Device testing (biometrics, photo picker, auto-lock edge cases, large files/perf)
- Thumbnails (currently decrypts full images with `cacheWidth`); streaming encryption for very large files
- Video playback, PDF preview; optional deletion of originals via MediaStore request
- In-vault notification list (brief week 3), Pro/paywall **UI stub only** (no billing), free-tier item limit
- Biometric-bound Keystore key + PIN-wrapped DEK hardening
- Release signing, hosted privacy policy URL, support e-mail, screenshots, Play Console (owner)
