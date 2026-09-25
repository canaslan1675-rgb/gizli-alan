# Store listing — English (en-US)

> **TR özet.** `play` flavor'u için İngilizce mağaza metni: başlıkta "Calculator Vault" var (cihazdaki "Calculator" etiketiyle tutarlı), açıklama kasayı, hesap makinesi girişini ve
> "ne değildir" bölümünü açıkça anlatır; anahtar kelime doldurma yok. En altta `full` (Second phone / iş profili) varyantı ve DEVICE-ADMIN açıklaması var.

## Rules (Metadata policy)
- Title ≤ 30, short ≤ 80, full ≤ 4000 characters; no emoji / ALL CAPS / "#1", "free", "best" in the title.
- Keywords only in natural sentences: *vault, encrypted, photos, notes, files, calculator, private*. No keyword lists, no competitor names.
- Avoid: "disguised", "no one will ever know", "hide from your partner/parents", "spy", "track".
- Only features that are in the build. No Pro/prices (no billing yet, #15).

## `play` flavor

**Title (27/30):**
```
GizliAlan: Calculator Vault
```
Alternative: `Calculator Vault: GizliAlan` (27).

**Short description (72/80):**
```
Encrypted vault for photos, files and notes behind a working calculator.
```

**Full description (1935/4000):**
```
GizliAlan is a private, on-device personal vault for the owner of the phone. Your photos, documents and notes are protected by a PIN (plus optional fingerprint/face unlock) and encrypted with AES-256-GCM on your device only.

CALCULATOR ENTRY – DISCLOSED
On your phone the app is named "Calculator" and has an original calculator icon. That icon is GizliAlan. It opens as a fully working calculator. Type your vault PIN and press "=" to open the vault; if you enabled biometrics, long-press "=". This is explained during setup, behind the ⓘ button on the calculator and in this description. You can turn it off in Settings so the app opens straight at the PIN screen.

FEATURES
• Encrypted gallery: add photos with the system picker, grid view, export or delete
• Encrypted notes (with search) and encrypted files (PDF etc.)
• A home screen of its own inside the vault, with wallpapers
• PIN + optional fingerprint/face, auto-lock when the app goes to the background
• Wrong-attempt limit with cool-down; the vault shows how many wrong PINs were entered since your last unlock
• Screenshots and recent-apps previews are blocked
• Optional decoy PIN: opens a separate second vault that starts empty (biometrics always open the real vault)
• English and Turkish

PRIVACY
• No account, no server, no ads, no analytics
• No tracking, no ads: the app sends none of your data anywhere. The built-in private browser only connects to sites you open, and its cookies/cache are wiped when the vault locks
• Minimal permissions: optional biometric unlock, and internet only for the built-in browser. You pick photos and files yourself; no storage permission
• Cloud backup is disabled; uninstalling deletes the vault
• There is no PIN recovery. If you forget your PIN, the content cannot be decrypted

WHAT IT IS NOT
• Not a tool to monitor, track or listen to anyone
• Does not read SMS, calls, contacts or location; no Accessibility Service; never an admin of your phone
• Does not lock or hide other apps
• Use it only on your own device, for your own content

Privacy policy and support e-mail are on this page.
```

**Category:** Tools.

**Screenshot order and captions** (`docs/store/screenshots/play/en/`):
1. `01_calculator_info.png` — "A real calculator. The ⓘ button explains the vault."
2. `02_onboarding_disclosure.png` — "Disclosed during setup. Turn it off any time."
3. `03_vault_home.png` — "The vault's own home screen."
4. `04_gallery.png` — "Encrypted gallery."
5. `05_notes.png` — "Encrypted notes with search."
6. `06_settings.png` — "PIN, biometrics, auto-lock, decoy PIN."

**Release notes (first release):**
```
First release: encrypted gallery, notes and files; calculator entry (PIN + "="); biometric unlock.
```

---

## `full` flavor variant (only if the owner submits `full` to Play)

**Title (30/30):**
```
GizliAlan Vault & Work Profile
```

**Short description (71/80):**
```
Encrypted calculator vault + a separate space via Android work profile.
```

**Full description (3073/4000):**
```
GizliAlan is a private, on-device personal vault for the owner of the phone. Your photos, documents and notes are protected by a PIN (plus optional fingerprint/face unlock) and encrypted with AES-256-GCM on your device only.

CALCULATOR ENTRY – DISCLOSED
On your phone the app is named "Calculator" and has an original calculator icon. That icon is GizliAlan. It opens as a fully working calculator. Type your vault PIN and press "=" to open the vault; if you enabled biometrics, long-press "=". This is explained during setup, behind the ⓘ button on the calculator and in this description. You can turn it off in Settings so the app opens straight at the PIN screen.

FEATURES
• Encrypted gallery: add photos with the system picker, grid view, export or delete
• Encrypted notes (with search) and encrypted files (PDF etc.)
• A home screen of its own inside the vault, with wallpapers
• PIN + optional fingerprint/face, auto-lock when the app goes to the background
• Wrong-attempt limit with cool-down; the vault shows how many wrong PINs were entered since your last unlock
• Screenshots and recent-apps previews are blocked
• Optional decoy PIN: opens a separate second vault that starts empty (biometrics always open the real vault)
• English and Turkish

SECOND PHONE (OPTIONAL, ANDROID WORK PROFILE)
• "Second phone" creates a separate space with Android's own work profile feature (the Shelter/Island method). Android's own consent screens run the setup
• Add a second Google account in that space's own Play Store and install apps, or add an app from your main phone. Apps, accounts and files are kept apart from your main phone by Android
• Optionally hide that space's apps when you lock the vault, and launch them from inside the vault
• DEVICE ADMIN PRIVILEGE: GizliAlan is only the profile owner of the work profile you create; this uses Android's device-admin component with no admin policies (no password, lock or wipe control). It is never an admin of your phone and switches itself off if activated that way
• Does not read the data, messages or notifications of apps in the work profile
• Remove it in the app ("Remove second phone") or in Android Settings > Accounts > Work profile
• Some devices (e.g. Xiaomi MIUI/HyperOS) may not support work profiles

PRIVACY
• No account, no server, no ads, no analytics
• No tracking, no ads: the app sends none of your data anywhere. The built-in private browser only connects to sites you open, and its cookies/cache are wiped when the vault locks
• One permission only: optional biometric unlock (the work profile needs no extra permission). You pick photos and files yourself; no storage permission
• Cloud backup is disabled; uninstalling deletes the vault
• There is no PIN recovery. If you forget your PIN, the content cannot be decrypted

WHAT IT IS NOT
• Not a tool to monitor, track or listen to anyone
• Does not read SMS, calls, contacts or location; no Accessibility Service; never a device admin of your phone
• Does not lock or hide apps on your main phone; only hides apps in its own work profile when you ask it to
• Use it only on your own device, for your own content

Privacy policy and support e-mail are on this page.
```

The "DEVICE ADMIN PRIVILEGE" bullet mirrors how Island (10M+ installs, on Play) discloses its device-admin use in its listing (see RESEARCH.md §3.2).

**Extra screenshots needed:** Second phone intro screen (GizliAlan's explanation before Android's own consent), profile app grid, "Remove second phone". (Not yet in `docs/store/screenshots/full/`.)
