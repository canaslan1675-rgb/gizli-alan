# Privacy Policy — GizliAlan (Hidden Space)

**Last updated:** 2026-09-20  
**App:** GizliAlan / Hidden Space  
**Package:** `com.offerforge.gizlialan`  
**Audience:** Device owner (personal use)

## Summary / Özet

GizliAlan stores notes and files **only on your device**. We do not operate servers that receive your vault content. There is no account system, no analytics SDK in this MVP, and no advertising ID collection by the app itself.

GizliAlan, notlarınızı ve dosyalarınızı **yalnızca cihazınızda** saklar. Kasa içeriğini alan bir sunucumuz yoktur.

## Data we store (on-device)

| Data | Where | Purpose |
|------|-------|---------|
| PIN hash + salt | `flutter_secure_storage` (Android Keystore-backed when available) | Unlock vault |
| App settings | `shared_preferences` | Encryption toggle, decoy, lock timeout |
| Notes JSON | App documents directory | Personal notes |
| Imported files | App documents `/vault_files/` | Personal files (optionally AES-encrypted) |

## Data we do NOT collect

- No SMS / call logs
- No contacts scraping
- No location tracking
- No microphone / camera background capture
- No accessibility-service based observation of other apps
- No overlay windows for surveillance
- No cloud backup of vault contents by this app

## Encryption

- **Default:** files and notes are stored in the app sandbox (hide-only). Not visible to other apps without root or backup extractions.
- **Optional:** AES encryption for file payloads when enabled in Settings. Key material is derived/stored via secure storage.
- Encryption does **not** make the app invisible in the launcher. For OS-level hiding, use Android Private Space (Android 15+) when available.

## Permissions (intended)

MVP aims for minimal permissions:
- Storage / file pick via system file picker (`file_picker`) — user-initiated imports only
- No SMS, no Accessibility, no Device Admin, no Notification Listener for spying

Exact `AndroidManifest` permissions depend on plugin versions; review before Play upload and remove unused ones.

## Third parties

This MVP ships without Firebase, Crashlytics, or ads. If you add them later, update this policy.

## Children’s privacy

Not directed at children under 13. Personal vault for the account holder.

## Contact

Device owner / developer: Demirhan (personal project).  
For Play Store: replace this line with a real contact email before publishing.

## Your rights

Uninstalling the app removes the app sandbox (subject to Android backup settings). Clear app data to wipe the vault without uninstalling.

---

*This document is provided for transparency and Play policy readiness. It is not legal advice.*
