import 'package:flutter/material.dart';

/// Dark mint aesthetic from UI research.
/// Background: #0B1220 · Accent: #7CFFB2
class GizliTheme {
  static const Color bg = Color(0xFF0B1220);
  static const Color bgElevated = Color(0xFF121A2B);
  static const Color bgCard = Color(0xFF162033);
  static const Color mint = Color(0xFF7CFFB2);
  static const Color mintDim = Color(0xFF3D9A6C);
  static const Color textPrimary = Color(0xFFE8EEF7);
  static const Color textSecondary = Color(0xFF9AA8BC);
  static const Color danger = Color(0xFFFF6B7A);
  static const Color warning = Color(0xFFFFC857);

  /// Vault home wallpapers (gradients, no image assets needed).
  static const List<List<Color>> wallpapers = [
    [Color(0xFF0B1220), Color(0xFF12324A), Color(0xFF0E5A4A)],
    [Color(0xFF1A0B2E), Color(0xFF3B1F5C), Color(0xFF7A2E6B)],
    [Color(0xFF0B1220), Color(0xFF1E2A44), Color(0xFF3A4A6B)],
    [Color(0xFF2B1305), Color(0xFF6B3410), Color(0xFFB8641B)],
    [Color(0xFF03161A), Color(0xFF0B3B45), Color(0xFF1B7A8C)],
  ];

  /// Readability scrim over a photo background on the vault home.
  static const double homePhotoScrim = 0.45;

  /// Bundled default vault-home background (owner-provided, light image).
  static const String defaultWallpaperAsset = 'assets/wallpapers/default.jpg';

  /// Top/bottom darkening over image backgrounds so the clock, tiles, dock
  /// and the signature stay readable on light photos.
  static const LinearGradient homeImageScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x8C000000),
      Color(0x33000000),
      Color(0x26000000),
      Color(0x40000000),
      Color(0xA6000000),
    ],
    stops: [0.0, 0.3, 0.55, 0.78, 1.0],
  );

  static LinearGradient wallpaper(int i) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: wallpapers[i.clamp(0, wallpapers.length - 1)],
  );

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        surface: bg,
        primary: mint,
        secondary: mintDim,
        error: danger,
        onPrimary: bg,
        onSurface: textPrimary,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: mint, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mint,
          foregroundColor: bg,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Explicit family (Android's default anyway) so widget-rendered
          // store screenshots don't fall back to the test font.
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: mint),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: mint,
        foregroundColor: bg,
      ),
      dividerColor: textSecondary.withValues(alpha: 0.2),
      listTileTheme: const ListTileThemeData(
        iconColor: mint,
        textColor: textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgCard,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
