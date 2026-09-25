/// English strings.
const Map<String, String> en = {
  'appName': 'GizliAlan',
  // Launcher / recents label (Android string resource says the same).
  'launcherName': 'Calculator',
  'appNameVault': 'GizliAlan Vault',
  'decoyTitle': 'Calculator',
  // Onboarding
  'onboardingTitle': 'Welcome to GizliAlan',
  'onboardingBody':
      'GizliAlan is a personal vault for the owner of this phone: private '
      'photos, notes and files, protected by a PIN (and optionally your '
      'fingerprint/face), encrypted on this device.',
  'onboardingPrivacy':
      'Not a monitoring tool. GizliAlan never reads SMS, calls, contacts or location, uses no Accessibility Service, is never an admin of your phone, and has no server: it sends nothing about you anywhere (the built-in browser only loads the pages you open). (The optional "Second phone" only manages the separate work profile you create yourself.) Only use it for your own content on your own device.',
  'ownDeviceConfirm':
      'This is my own device and I will only store my own content.',
  'entryTitle': 'Calculator entry',
  'entryBody':
      'GizliAlan can open as a normal, fully working calculator. To enter the '
      'vault, type your PIN and press "=". Long-press "=" to use biometrics '
      '(if enabled).',
  'entryDisclosure':
      'This is a disclosed feature, described in the store listing and in '
      'the calculator\'s ⓘ button. In your app list this app appears as '
      '"Calculator" with a simple calculator icon — that icon is GizliAlan. '
      'You can switch the calculator entry off any time in Settings.',
  'calculatorEntry': 'Open as calculator',
  'calculatorEntryOn':
      'App starts as a calculator — PIN then "=" opens the vault',
  'calculatorEntryOff': 'App starts at the PIN screen',
  'setPin': 'Set PIN',
  'confirmPin': 'Confirm PIN',
  'pinFormat': 'PIN must be 4–8 digits',
  'pinMismatch': 'PINs do not match',
  'pinNoRecovery':
      'Important: there is no PIN recovery. If you forget your PIN, the '
      'vault content cannot be decrypted. Only a full reset is possible.',
  'finishSetup': 'Create vault',
  'continue': 'Continue',
  'back': 'Back',
  'dataSafetyShort':
      'Data stays on this device, encrypted. No account, no cloud, no ads, no analytics.',
  // Calculator
  'calcInfoTitle': 'About this calculator',
  'calcInfoBody':
      'This is a real calculator and also the entrance to your GizliAlan '
      'vault (it is listed as "Calculator" in your app list): type your '
      'vault PIN and press "=" to open it. Long-press "=" for biometric '
      'unlock if enabled. You can turn the calculator entry off in the vault '
      'settings.',
  // Lock
  'unlock': 'Enter PIN',
  'wrongPin': 'Wrong PIN',
  'lockedOut': 'Too many attempts. Try again in {s} s.',
  'lockedOutShort': 'Too many attempts. Try again later.',
  'useBiometric': 'Use biometrics',
  'biometricReason': 'Unlock GizliAlan vault',
  'biometricEnableReason': 'Confirm to enable biometric unlock',
  // Home
  'gallery': 'Gallery',
  'notes': 'Notes',
  'files': 'Files',
  'settings': 'Settings',
  'lock': 'Lock',
  // Gallery / files
  'importPhotos': 'Add photos',
  'importFile': 'Add file',
  'importing': 'Encrypting…',
  'importedN':
      '{n} photo(s) encrypted into the vault. The originals are still in your '
      'phone gallery — delete them there if you want.',
  'importedFilesN':
      '{n} file(s) encrypted into the vault. The originals were not changed.',
  'tooBig': 'Some files were larger than 100 MB and were skipped.',
  'emptyGallery':
      'No photos yet.\nTap "Add photos" — they are encrypted on this device.',
  'emptyFiles':
      'No files yet.\nAdd PDFs or other documents — they stay encrypted on this device.',
  'view': 'View',
  'export': 'Export',
  'exported': 'Exported (decrypted copy saved where you chose)',
  'exportFailed': 'Export failed',
  'delete': 'Delete',
  'deleteItemConfirm': 'Permanently delete this item from the vault?',
  // Notes
  'newNote': 'New note',
  'editNote': 'Edit note',
  'untitled': 'Untitled',
  'noteTitle': 'Title',
  'noteBody': 'Note',
  'save': 'Save',
  'search': 'Search',
  'emptyNotes':
      'No notes yet.\nYour first private note stays encrypted on this device.',
  'deleteNoteConfirm': 'Delete this note?',
  // Settings
  'security': 'Security',
  'changePin': 'Change PIN',
  'currentPin': 'Current PIN',
  'newPin': 'New PIN',
  'wrongCurrentPin': 'Current PIN is wrong',
  'pinSaved': 'PIN saved',
  'pinMustDiffer': 'Real PIN and decoy PIN must be different',
  'biometric': 'Biometric unlock',
  'biometricHint': 'Fingerprint/face opens the real vault (never the decoy)',
  'biometricUnavailable': 'No biometrics enrolled on this device',
  'decoyPin': 'Decoy PIN (optional)',
  'decoyPinOn': 'On — the decoy PIN opens a separate, empty vault',
  'decoyPinOff': 'Off',
  'decoyPinExplain':
      'A decoy PIN opens a second, separate vault that starts empty and has '
      'its own encryption key. Your real vault is not shown there. It must '
      'differ from your real PIN. This feature is described in the store '
      'listing.',
  'decoyRemove': 'Remove decoy PIN',
  'decoyRemoveConfirm':
      'Remove the decoy PIN and delete everything stored in the decoy vault?',
  'screenSecurity': 'Screen protection',
  'screenSecurityHint':
      'Always on: screenshots, screen recording and the recent-apps preview are blocked (FLAG_SECURE)',
  'entry': 'Entry',
  'general': 'General',
  'lockTimeout': 'Auto-lock',
  'lockTimeoutHint': 'Locks when the app goes to the background',
  'lockImmediately': 'Immediately',
  'lockAfterSec': 'After {n} s',
  'lockAfterMin': 'After {n} min',
  'language': 'Language',
  'wallpaper': 'Wallpaper',
  'homeBackground': 'Home screen background',
  'homeBackgroundDefault':
      'Default (colour below). To use a photo: Gallery → long-press a photo → "Set as home background".',
  'homeBackgroundPhoto':
      'A photo from this vault. Remove it to go back to the colour below.',
  'homeBackgroundRemove': 'Remove background',
  'homeBackgroundSet':
      'Set as the vault home background. The photo stays encrypted in the vault.',
  'setAsHomeBackground': 'Set as home background',
  'open': 'Open',
  'browser': 'Browser',
  'browserHint': 'Search or type a web address',
  'browserSearchWith':
      'Searches use {engine}. No search suggestions are sent while you type.',
  'browserPrivacyNote':
      'Private browser inside the vault. GizliAlan adds no tracking, analytics or ads — only the sites you open are contacted. Third-party cookies are blocked, history is kept only while this screen is open, and cookies, cache and site data are erased when the vault locks (Settings → Browser). Sites can still see your IP address, like any browser. Downloads, file uploads, location, camera and microphone are off. Android System WebView may check pages with Google Safe Browsing (Android default).',
  'browserBack': 'Back',
  'browserForward': 'Forward',
  'browserReload': 'Reload',
  'browserBlockedLink':
      'This kind of link (app, phone, e-mail, file…) is not opened from the vault browser.',
  'browserEngine': 'Search engine',
  'browserWipeOnLock': 'Clear on lock',
  'browserWipeOnLockHint':
      'Erase browser cookies, cache and site data whenever the vault locks.',
  'browserWipeNow': 'Clear browser data now',
  'browserWiped': 'Browser data cleared.',
  'privacyTitle': 'Privacy & permissions',
  'privacyBody':
      '• All vault content (photos, files, notes) is encrypted with AES-256-GCM '
      'using a key kept in Android Keystore-backed secure storage.\n'
      '• Your PIN is stored only as a salted PBKDF2 hash.\n'
      '• No account, no analytics, no telemetry, no ads, no server of ours. '
      'Nothing leaves your device unless you export it — or open a web page '
      'in the built-in private browser, which then talks only to that site '
      '(the reason for the internet permission).\n'
      '• Permissions: biometric (optional unlock) and internet (browser '
      'only). Photos and files are '
      'chosen by you through the system pickers — no storage/media '
      'permission.\n'
      '• No SMS, calls, contacts, location, microphone, camera, Accessibility '
      'or main-device admin. The optional Second phone is only the profile '
      'owner of the work profile you create.\n'
      '• App backup is disabled, so vault data is not copied to the cloud. '
      'Uninstalling or "Clear data" deletes the vault.',
  'dangerZone': 'Danger zone',
  'wipeVault': 'Reset everything',
  'wipeHint': 'Deletes all vaults, PINs and keys',
  'wipeConfirm':
      'All photos, files and notes in all vaults, plus your PINs and keys, '
      'will be permanently deleted. Continue?',
  'cancel': 'Cancel',
  'ok': 'OK',
  // Second phone (work profile)
  'secondPhone': 'Second phone',
  'secondPhoneApps': 'Second phone apps',
  'spIntro':
      'Second phone creates a separate space on this device using Android\'s own "work profile" feature (the same method Shelter/Island use). It has its own Play Store where you can add a separate Google account and install apps. Apps, accounts and files stay separate from your main phone.',
  'spDisclosure':
      'How it works: GizliAlan becomes the "profile owner" only of this work profile it creates. It is not an admin of your main profile or of the device; it monitors nothing, reads no other app\'s data and sends nothing anywhere. Android shows its own notice during setup. Profile apps carry a briefcase badge and also appear in the "Work" tab of your app list. Setup and management are only possible while the vault is unlocked.',
  'spSetUp': 'Set up second phone',
  'spSetUpConfirm':
      'Android will now start work profile setup. It can take a few minutes and shows system screens. Continue?',
  'spCreated':
      'Second phone is ready. Open Play Store to add your second Google account.',
  'spCreatedPending':
      'Setup finished; Android is still preparing the profile. Check again in a few seconds.',
  'spCanceled': 'Setup was cancelled or could not be completed.',
  'spXiaomiWarn':
      'On Xiaomi / Redmi / POCO (MIUI/HyperOS) devices work profile setup is often blocked or left half-finished. You can still try; if it fails, use the phone\'s own "Second space" (Settings → Special features → Second space).',
  'spXiaomiBlocked':
      'This Xiaomi/Redmi/POCO device (MIUI/HyperOS) does not allow creating a work profile. Alternative: the built-in "Second space" (Settings → Special features → Second space), or on Android 15+ "Private space" (Settings → Security & privacy → Private space).',
  'spNotAllowed':
      'A work profile can\'t be created on this device right now, usually because one already exists (e.g. a company account) or the manufacturer disabled it. Alternative: Android 15+ "Private space" or the manufacturer\'s second space / secure folder.',
  'spUnsupported':
      'This device does not support Android work profiles. Alternative: Android 15+ "Private space" or the manufacturer\'s feature (Samsung Secure Folder, Xiaomi Second space).',
  'spPrivateSpaceHint':
      'This phone runs Android 15 or newer: "Private space" (Settings → Security & privacy → Private space) also gives you an OS-level separate space.',
  'spUnlinked':
      'A work profile with GizliAlan exists on this device but is not linked to this vault (app data may have been cleared). To remove it: Android Settings → Accounts (or Passwords & accounts) → Work → Remove work profile. Then set it up again.',
  'spStatus': 'Status',
  'spStatusOpen': 'Open',
  'spStatusFrozen': 'Closed — apps hidden',
  'spStatusQuiet': 'Closed — apps hidden, work profile paused',
  'spOpenStore': 'Open Play Store (second account)',
  'spAddApp': 'Add an app from the main phone',
  'spAddAppHint':
      'System apps are copied directly; for other apps the second phone\'s Play Store page opens.',
  'spCloseNow': 'Close second phone now',
  'spOpenNow': 'Open second phone',
  'spRemove': 'Remove second phone',
  'spRemoveConfirm':
      'The work profile and ALL apps, accounts and files in it will be permanently deleted. Continue?',
  'spRemoved': 'Second phone removed.',
  'spCloneOk': '"{app}" was added to the second phone.',
  'spCloneStore':
      'Android does not allow copying this app directly. The second phone\'s Play Store page was opened; install it there (add your second account first).',
  'spCloneFailed':
      'Could not add the app. You can install it from the second phone\'s Play Store.',
  'spNoApps':
      'No apps in the second phone yet. Install from Play Store or add from the main phone.',
  'spNoCandidates': 'No apps available to add.',
  'spFailed': 'Could not complete the action ({s}).',
  'spClosed': 'Second phone closed.',
  'spOpened': 'Second phone opened.',
  'spQuietFallback':
      'Apps hidden. Android did not allow pausing the work profile.',
  'spHideWhenLocked': 'Hide work apps while locked',
  'spHideWhenLockedHint':
      'While the vault is locked, second-phone apps are removed from the phone\'s home screen, its "Work" folder and the app list. Nothing is uninstalled and their data stays. They come back when you unlock with your real PIN or fingerprint. While hidden they do not run and receive no notifications.',
  'spHideWhenLockedWhen':
      'Hidden immediately when you press Lock. After a background auto-lock Android does not let GizliAlan act, so the apps are hidden the next time GizliAlan is open while locked (app start or return). Kept visible: GizliAlan itself and Google Play services / installer / settings components needed to manage the profile.',
  'spPauseToo': 'Also try to pause the work profile',
  'spPauseTooHint':
      'Android lets only the default home-screen app pause a work profile, so on most phones only hiding takes effect. A paused profile\'s icons stay visible (greyed out) in some launchers, e.g. Xiaomi — hiding is what removes them. You can also use the "Work apps" quick-settings tile.',
  'notifications': 'Notifications',
  'notifEmpty':
      'No notifications yet. Imports, exports, deletions, Second phone changes and wrong PIN attempts are listed here.',
  'notifFooter':
      'This list is only visible inside the vault and is stored encrypted. GizliAlan posts no system notifications and never reads other apps\' notifications.',
  'notifMarkAllRead': 'Mark all as read',
  'notifClearAll': 'Clear all',
  'notifClearConfirm': 'Delete all notifications of this vault?',
  'evGalleryImported': '{n} photo(s) added to Gallery',
  'evFilesImported': '{n} file(s) added to Files',
  'evItemExported': '"{name}" exported',
  'evItemDeleted': '"{name}" deleted',
  'evFailedUnlocks': '{n} wrong PIN attempt(s) since your last unlock',
  'evSecondPhoneCreated': 'Second phone created',
  'evSecondPhoneAppAdded': '"{app}" added to the second phone',
  'evSecondPhoneRemoved': 'Second phone removed',
  'proTitle': 'GizliAlan Pro',
  'proSettingsHint': 'Plans and prices (no purchases in this test build)',
  'proTestBuildNote':
      'This is a test build: there are no purchases and no payment is taken. Prices are planned prices.',
  'proFree': 'Free',
  'proFreePrice': '0 TL',
  'proFreeF1': 'Basic vault, up to {max} items',
  'proFreeF2': 'No ads',
  'proFreeF3': 'All data encrypted on your device',
  'proUsage': 'Usage: {n} / {max} items (limit not enforced in this build)',
  'proCurrent': 'Current',
  'proLifetime': 'Pro — one-time',
  'proLifetimePrice': '249 TL (about 7.99 USD)',
  'proYearly': 'Pro — yearly',
  'proYearlyPrice': '449 TL / year',
  'proF1': 'Unlimited items',
  'proF2': 'No ads',
  'proF3': 'All data encrypted on your device',
  'proBuy': 'Buy',
  'proSubscribe': 'Subscribe',
  'proNotAvailableTitle': 'Not available yet',
  'proNotAvailableBody':
      'There are no purchases in this test build and no payment is taken. Pro may be offered through Google Play later.',
  'proFooter':
      'GizliAlan needs no account and sends no data to any server. The app is not sold on Gumroad or elsewhere.',
  // `play` flavor variants (no Second phone in that build), see L10n.t.
  'onboardingPrivacy_play':
      'Not a monitoring tool. GizliAlan never reads SMS, calls, contacts or location, uses no Accessibility Service, is never an admin of your phone, and has no server: it sends nothing about you anywhere (the built-in browser only loads the pages you open). Only use it for your own content on your own device.',
  'privacyBody_play':
      '• All vault content (photos, files, notes) is encrypted with AES-256-GCM '
      'using a key kept in Android Keystore-backed secure storage.\n'
      '• Your PIN is stored only as a salted PBKDF2 hash.\n'
      '• No account, no analytics, no telemetry, no ads, no server of ours. '
      'Nothing leaves your device unless you export it — or open a web page '
      'in the built-in private browser, which then talks only to that site '
      '(the reason for the internet permission).\n'
      '• Permissions: biometric (optional unlock) and internet (browser '
      'only). Photos and files are '
      'chosen by you through the system pickers — no storage/media '
      'permission.\n'
      '• No SMS, calls, contacts, location, microphone, camera, Accessibility '
      'or device admin.\n'
      '• App backup is disabled, so vault data is not copied to the cloud. '
      'Uninstalling or "Clear data" deletes the vault.',
  'notifEmpty_play':
      'No notifications yet. Imports, exports, deletions and wrong PIN attempts are listed here.',
  // Privacy policy link (#28), shown only when PRIVACY_URL is set.
  'privacyPolicyOnline': 'Full privacy policy (online):',
  'openInBrowser': 'Open in browser',
  'copyLink': 'Copy link',
  'linkCopied': 'Link copied',
  'noBrowser': 'No browser found. The link was copied instead.',
};
