# Bundled wallpaper slot (currently empty)

Reserved for an optional bundled default background for the vault home screen.
Nothing here is shipped right now: the default is the plain gradient
(`GizliTheme.wallpapers`), and the owner can pick one of his own vault photos in
Settings → "Ana ekran arka planı / Home screen background".

To add a bundled default later:
1. Put a compressed image here (e.g. `default.webp`, 1080×2400, < 300 KB).
2. Declare it in `pubspec.yaml` under `flutter: assets:`.
3. Use it in `VaultHomeScreen` when no vault photo is chosen (keep the
   `GizliTheme.homePhotoScrim` scrim for readability).

This folder is not listed in pubspec.yaml, so this README is not bundled into the APK.
