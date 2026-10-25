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
  'calcInfoProHint': 'Pro members can hide this icon in Settings.',
  'hideCalcInfo': 'Hide info icon on calculator',
  'hideCalcInfoHint':
      'Removes the ⓘ button from the calculator. Help: Settings → About calculator entry.',
  'hideCalcInfoLocked': 'Pro feature. Tap to open the Pro screen.',
  'proSoon': 'Pro coming soon',
  'calcHelpTitle': 'About calculator entry',
  'calcHelpHint': 'How the vault opens (same text as ⓘ)',
  'proStubToggle': 'Simulate Pro (test build)',
  'proStubToggleHint': 'No purchase; a local switch to try Pro features only.',
  'deleteOriginal': 'Delete original after import',
  'deleteOriginalHint':
      'The phone original is deleted once saved in the vault.',
  'deleteOriginalAskTitle': 'Delete originals from the gallery?',
  'deleteOriginalAskBody':
      'If you turn this on, photos you import into the vault are deleted from the phone gallery from now on. You can change it in Settings.',
  'deleteOriginalAskYes': 'Yes, delete',
  'deleteOriginalAskNo': 'No',
  'proSettingsHint_play': "Buy or restore Pro",
  'payIntro':
      "The vault, encryption, calculator entry and browser are free. Buy Pro once to unlock:",
  'payF1': 'Second phone (work profile) setup',
  'payF2': 'Unlimited items (free: {max})',
  'payF3': 'Hide the ⓘ icon on the calculator',
  'payMonthly': 'Monthly',
  'payYearly': 'Yearly',
  'payPerMonth': '{price} / month',
  'payPerYear': '{price} / year',
  'payF4': "Future updates included",
  'payLifetime': "GizliAlan Pro – one-time",
  'payLifetimeSub': "Pay once, yours forever. No subscription.",
  'payBuyOnce': "Buy once – {price}",
  'itemCounter': '{n} items',
  'quickLock': 'Lock now',
  'failedSummary': '{n} wrong attempts since your last entry',
  'pinHint': 'PIN hint',
  'pinHintOptional': 'PIN hint (optional)',
  'pinHintSub': 'Shown when you long-press the calculator display',
  'pinHintExplain':
      'Write a short reminder only you understand; never the PIN itself. Stored encrypted on the device and shown when you long-press the calculator\'s result display. There is no e-mail or server recovery.',
  'pinHintBad': 'The hint cannot contain the PIN and is at most 60 characters.',
  'trash': 'Recycle bin',
  'trashSub': 'Deleted items are kept for 30 days, then deleted for good',
  'trashEmpty': 'The recycle bin is empty',
  'trashEmptyAll': 'Empty recycle bin',
  'trashEmptyConfirm':
      'Delete everything in the recycle bin for good? This cannot be undone.',
  'trashRestore': 'Restore',
  'trashDeleteForever': 'Delete for good',
  'trashDaysLeft': 'Deleted in {d} days',
  'trashRestored': 'Restored',
  'trashKindPhoto': 'Photo',
  'trashKindFile': 'File',
  'trashKindNote': 'Note',
  'recentApps': 'Recently opened',
  'albumAll': 'All',
  'albumNew': 'New album',
  'albumName': 'Album name',
  'albumRename': 'Rename',
  'albumDelete': 'Delete album',
  'albumDeleteSub': 'Photos stay in the gallery',
  'albumMoveTo': 'Move to album',
  'albumRemoveFrom': 'Remove from album',
  'albumEmpty':
      'This album is empty. Long-press a photo and choose "Move to album".',
  'albumLimitTitle': '1 album in the free version',
  'albumLimitBody':
      'The free version has one album. Pro unlocks unlimited albums; your existing albums and photos stay as they are.',
  'freeBannerTitle': "You're on the limited free version (up to {max} items)",
  'freeBannerBody':
      "Buy Pro once for {price}: removes the limit, unlocks Second phone (work profile) and includes future updates.",
  'freeBannerBodyPlay':
      "Buy Pro once for {price}: removes the item limit and includes future updates.",
  'freeBannerCta': "Get Pro",
  'freeBannerDismiss': "Dismiss",
  'payTrial': 'Starts with a free trial',
  'payLoading': 'Getting prices from Google Play…',
  'payUnavailable':
      'Google Play is not available right now. Check your internet connection and Play Store sign-in.',
  'payNoPlans': "Couldn't load the Pro product. Try again later.",
  'payRestore': 'Restore purchases',
  'payManage': "Manage an older subscription in Google Play",
  'payTerms':
      "One-time payment: no subscription, no auto-renewal, no free trial. Charged to your Google Play account. If you subscribed before, Pro stays active for your subscription.",
  'payActive': 'Pro is active. Thank you!',
  'payPurchased': 'Pro activated. Thank you!',
  'payPending': 'Payment pending. Pro turns on once it is confirmed.',
  'payCanceled': 'Purchase cancelled.',
  'payError': "The purchase couldn't be completed. Try again.",
  'payRestored': 'Pro restored.',
  'payNothing': "No Pro purchase found on this Google account.",
  'payOffline': "Couldn't reach Google Play. Check your connection.",
  'notNow': 'Not now',
  'proSeePlans': 'See Pro',
  'limitTitle': 'Free limit reached',
  'limitBody':
      "The free version stores up to {max} items (photos, files, notes). Your existing items are never locked or deleted. Buy Pro once to remove the limit.",
  'spProTitle': 'Second phone comes with Pro',
  'spProBody':
      "Second phone is a Pro feature. Buy Pro once with a one-time payment; no subscription.",
  'supportEmail': 'Support',
  'copyEmail': 'Copy e-mail',
  'emailCopied': 'E-mail address copied',
  'privacyPolicy': 'Privacy policy',
  'originalsDeletedN': '{n} original(s) deleted.',
  'originalsKeptN':
      '{n} original(s) could not be deleted; the vault copy is safe.',
  'originalsDeclined':
      'Originals were not deleted (not confirmed); the vault copy is safe.',
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
  'deleteItemConfirm':
      'Move this item to the recycle bin? It is deleted for good after 30 days.',
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
  'deleteNoteConfirm':
      'Move this note to the recycle bin? It is deleted for good after 30 days.',
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
  'lockTimeout': 'Lock delay',
  'lockTimeoutHint':
      'Locks the vault this long after you leave the app or the screen turns off. Come back sooner and no PIN is needed.',
  'lockImmediately': 'Immediately',
  'lockAfter30': '30 seconds',
  'lockAfter60': '1 minute',
  'lockAfterSec': 'After {n} s',
  'lockAfterMin': 'After {n} min',
  'language': 'Language',
  'wallpaper': 'Wallpaper',
  'homeBackground': 'Home screen background',
  'homeBackgroundDefault':
      'Default (picture or colour below). To use a photo: Gallery → long-press a photo → "Set as home background".',
  'homeBackgroundPhoto':
      'A photo from this vault. Remove it to go back to the default below.',
  'wallpaperDefaultImage': 'Default picture',
  'wallpaperPlain': 'Plain colour',
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
      'Private browser inside the vault; no tracking or ads. Cookies and history are erased when the vault locks; downloads go to the encrypted vault.',
  'browserBack': 'Back',
  'browserForward': 'Forward',
  'browserReload': 'Reload',
  'browserBlockedLink':
      'This kind of link (app, phone, e-mail, file…) is not opened from the vault browser.',
  'browserSaveImage': 'Save image to vault',
  'browserDownloading': 'Downloading into the vault…',
  'browserSavedPhotos': 'Saved to vault Photos: {name}',
  'browserSavedFiles': 'Saved to vault Files: {name}',
  'browserDlTooLarge': 'Too large to save (max {mb} MB).',
  'browserDlNotImage': 'This is not an image.',
  'browserDlUnsupported': 'This download cannot be saved (unsupported link).',
  'browserDlFailed': 'Download failed.',
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
      'Before you continue: Android will create a separate work profile on this phone (this uses Android\'s device-management API, shown by Android as a work profile). GizliAlan becomes the profile owner of that new profile only; it is not an admin of your main profile or device and requests no admin policies such as password, lock or wipe. Inside the work profile GizliAlan\'s own icon is not shown. If "Hide work apps while locked" is on (default), apps in the work profile are hidden from your launcher whenever the vault is locked; nothing is uninstalled and you can switch this off on this screen. You can remove everything with "Remove second phone" or in Android Settings > Accounts > Work profile. Android shows its own notices next. Continue?',
  'spCreated':
      'Second phone is ready. Open Play Store to add your second Google account.',
  'spCreatedPending':
      'Setup finished; Android is still preparing the profile. Check again in a few seconds.',
  'spCanceled': 'Setup was cancelled or could not be completed.',
  'spXiaomiWarn':
      "Info: on Xiaomi / Redmi / POCO (MIUI/HyperOS) devices setup works on many models (tested e.g. on Redmi, MIUI 12.5.7). Some models may restrict work profiles; if so, you can use the phone's own \"Second space\" (Settings → Special features → Second space).",
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
  'spWorkGuideTitle': 'Also hide the Work tab',
  'spWorkGuideBody':
      'GizliAlan hides the work apps while the vault is locked. To also turn off or pause the launcher\'s Work tab yourself, the next step opens the system settings. Switch this off there:\n\n• Work profile / Work apps: turn off "Work apps" (pause work profile)\n• Xiaomi / POCO launcher: Home screen settings → turn off "Show work apps"\n• Otherwise: Settings → Accounts → Work profile → Pause\n\nTurn it back on in the same place (or from the Work tab) when you need it.',
  'spWorkGuideOpen': 'Open settings',
  'spWorkGuideLater': 'Not now',
  'spWorkGuideReopen': 'Open settings again',
  'spWorkGuideFailed':
      'Could not open the settings. Open Settings → Accounts → Work profile manually.',
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
  'proFreeF1': 'Up to {max} items',
  'proFreeF2': 'No ads',
  'proFreeF3': 'All data encrypted on your device',
  'proUsage': 'Usage: {n} / {max} items',
  'proCurrent': 'Current',
  'proMonthly': 'Pro — monthly',
  'proMonthlyPrice': '150 TL / month',
  'proYearly': 'Pro — yearly',
  'proYearlyPrice': '999 TL / year',
  'proYearlyHint': 'Save 45% · Best value',
  'proF1': 'Second phone',
  'proF2': 'Unlimited items',
  'proF3': 'Hide the ⓘ icon',
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
  // v0.5.1: appearance, help, share / rate / feedback (tester feedback)
  // v0.5.2: accent colour (tester feedback)
  'accentColor': 'Accent color',
  'accent_mint': 'Mint',
  'accent_blue': 'Blue',
  'accent_purple': 'Purple',
  'accent_orange': 'Orange',
  'accent_pink': 'Pink',
  'appearance': 'Appearance',
  'themeSystem': 'System',
  'themeLight': 'Light',
  'themeDark': 'Dark',
  'appearanceHint': 'Theme for the calculator and the vault screens',
  'helpFeedback': 'Help & feedback',
  'helpTitle': 'Help: how it works',
  'helpHint':
      'Calculator entry, appearance, share / rate / feedback, decoy PIN, vault',
  'helpCalcTitle': 'Calculator entry',
  'helpCalcBody':
      'The app appears in your app list as "Calculator" and opens as a real, working calculator. To open the vault, type your PIN and press "=". If biometric unlock is on, just long-press "=". Any number that is not your PIN is simply calculated. You can turn this entry off in Settings → Entry; the app then opens straight to the PIN screen.',
  'helpDecoyTitle': 'Decoy PIN',
  'helpDecoyBody':
      'In Settings → Security you can set a second PIN. The decoy PIN opens a separate vault that starts empty and has its own encryption key; your real vault and its content are not visible there. The decoy PIN must differ from your real PIN. Biometric unlock always opens the real vault only.',
  'helpVaultTitle': 'Vault',
  'helpVaultBody':
      'In the vault you can keep photos, notes and files (including videos and documents) and use the private browser. All content is encrypted on this device with AES-256-GCM; there is no account, no cloud and no server. Screenshots, screen recording and the recent-apps preview are blocked. Back moves to the previous screen inside the vault; it leaves the vault only from the home screen. The vault locks when you leave the app or the screen turns off; change the delay in Settings → Lock delay (Immediately, 30 seconds or 1 minute).',
  'helpPinTitle': 'What if I forget my PIN?',
  'helpPinBody':
      'There is no PIN recovery: your PIN is never sent anywhere and the content can only be decrypted on this device. If you forget your PIN, the vault content cannot be opened; you can only reset the app completely (or uninstall and reinstall it).',
  'helpSecondPhoneTitle': 'Second phone (work profile)',
  'helpSecondPhoneBody':
      'Second phone uses Android\'s own work-profile feature to create a separate space on this device. It has its own Play Store, so you can use a separate Google account and separate apps. Setup and management are only possible while the real vault is unlocked. Optionally, the work apps are hidden while the vault is locked and come back when you unlock. GizliAlan only manages the work profile it created; it does not monitor your main phone and sends no data anywhere.',
  'helpSecondPhonePro': 'Setting up the Second phone is a Pro feature.',
  // v0.5.3: appearance + share/rate/feedback help sections
  'helpAppearanceTitle': 'Appearance',
  'helpAppearanceBody':
      'In Settings → Appearance you can pick System, Light or Dark. Under Accent color you can choose mint, blue, purple, orange or pink. Theme and accent are stored only on this device; nothing is sent anywhere.',
  'helpShareTitle': 'Share, rate and feedback',
  'helpShareBody':
      'Under Settings → Help & feedback: Share app sends a short neutral message plus the Google Play link (you can edit the intro first). Rate app opens the Play listing. Send feedback opens your e-mail app with a category in the subject; you can optionally add what happened and what you expected. No device IDs, logs or vault data are attached automatically.',
  'shareApp': 'Share app',
  'shareAppHint': 'Send the Google Play link to a friend',
  // Neutral on purpose: never mention the vault in shared text.
  'shareAppText': 'Check out this app:',
  'shareIntroTitle': 'Share message',
  'shareIntroHint':
      'Keep it neutral — do not mention the vault, PIN or hidden features.',
  'shareAppFailed': 'Could not share. The link was copied instead.',
  'rateApp': 'Rate app',
  'rateAppHint': 'Rate or review it on Google Play',
  'rateAppFailed': 'Could not open Google Play. The link was copied instead.',
  'feedback': 'Send feedback',
  'feedbackHint': 'E-mail us ideas or bug reports',
  'feedbackSubject': 'GizliAlan feedback',
  'feedbackCategoryTitle': 'What is this about?',
  'feedbackCatBug': 'Bug',
  'feedbackCatSuggestion': 'Suggestion',
  'feedbackCatOther': 'Other',
  'feedbackBodyTitle': 'Optional details',
  'feedbackBodyWhat': 'What happened',
  'feedbackBodyExpected': 'What did you expect',
  'feedbackBodySkip': 'Skip',
  'feedbackFailed': 'No e-mail app found. The address was copied instead.',
};
