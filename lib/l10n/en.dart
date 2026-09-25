/// English strings.
const Map<String, String> en = {
  'appName': 'GizliAlan',
  'appNameVault': 'GizliAlan Vault',
  'decoyTitle': 'Calculator',
  // Onboarding
  'onboardingTitle': 'Welcome to GizliAlan',
  'onboardingBody':
      'GizliAlan is a personal vault for the owner of this phone: private '
      'photos, notes and files, protected by a PIN (and optionally your '
      'fingerprint/face), encrypted on this device.',
  'onboardingPrivacy':
      'Not a monitoring tool. GizliAlan never reads SMS, calls, contacts or '
      'location, uses no Accessibility Service or Device Admin, and uploads '
      'nothing — there is no server. Only use it for your own content on '
      'your own device.',
  'ownDeviceConfirm':
      'This is my own device and I will only store my own content.',
  'entryTitle': 'Calculator entry',
  'entryBody':
      'GizliAlan can open as a normal, fully working calculator. To enter the '
      'vault, type your PIN and press "=". Long-press "=" to use biometrics '
      '(if enabled).',
  'entryDisclosure':
      'This is a disclosed feature, described in the store listing and in '
      'the calculator\'s ⓘ button. The app icon and name in your launcher '
      'stay "GizliAlan". You can switch it off any time in Settings.',
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
      'vault: type your vault PIN and press "=" to open it. Long-press "=" '
      'for biometric unlock if enabled. You can turn the calculator entry off '
      'in the vault settings.',
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
  'privacyTitle': 'Privacy & permissions',
  'privacyBody':
      '• All vault content (photos, files, notes) is encrypted with AES-256-GCM '
      'using a key kept in Android Keystore-backed secure storage.\n'
      '• Your PIN is stored only as a salted PBKDF2 hash.\n'
      '• No internet permission in the release build, no account, no '
      'analytics, no ads. Nothing leaves your device unless you export it.\n'
      '• Permissions: biometric (optional unlock) only. Photos and files are '
      'chosen by you through the system pickers — no storage/media '
      'permission.\n'
      '• No SMS, calls, contacts, location, microphone, camera, Accessibility '
      'or Device Admin.\n'
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
};
