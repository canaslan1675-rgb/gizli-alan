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
  static const Color danger = Color(
    0xFFFF5252,
  ); // clear red (errors, danger zone)
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

  /// Theme for the dark palette (default look since v0.1).
  static ThemeData dark() => build(GizliColors.dark);

  /// Light palette (v0.5.1, tester request): same layout, darker accent so
  /// text and icons keep >= 4.5:1 contrast on light surfaces.
  static ThemeData light() => build(GizliColors.light);

  static ThemeData build(GizliColors c) {
    final isDark = c.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      scaffoldBackgroundColor: c.bg,
      colorScheme: isDark
          ? ColorScheme.dark(
              surface: c.bg,
              primary: c.accent,
              secondary: c.accentDim,
              error: c.danger,
              onPrimary: c.onAccent,
              onSurface: c.textPrimary,
              onSurfaceVariant: c.textSecondary,
            )
          : ColorScheme.light(
              surface: c.bg,
              primary: c.accent,
              secondary: c.accentDim,
              error: c.danger,
              onPrimary: c.onAccent,
              onSurface: c.textPrimary,
              onSurfaceVariant: c.textSecondary,
              surfaceContainerHighest: c.bgCard,
            ),
      extensions: [c],
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: c.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        labelStyle: TextStyle(color: c.textSecondary),
        hintStyle: TextStyle(color: c.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
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
        style: TextButton.styleFrom(foregroundColor: c.accent),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
      ),
      dividerColor: c.textSecondary.withValues(alpha: 0.2),
      listTileTheme: ListTileThemeData(
        iconColor: c.accent,
        textColor: c.textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.bgCard,
        contentTextStyle: TextStyle(color: c.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Theme-dependent colours. Screens on normal app surfaces read these via
/// `GizliColors.of(context)` so they follow the System / Light / Dark
/// setting. The vault home (always drawn on a dark wallpaper/photo with a
/// scrim) and the photo viewer keep the fixed dark [GizliTheme] constants.
@immutable
class GizliColors extends ThemeExtension<GizliColors> {
  const GizliColors({
    required this.brightness,
    required this.bg,
    required this.bgElevated,
    required this.bgCard,
    required this.accent,
    required this.accentDim,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.danger,
    required this.warning,
    required this.calcKey,
    required this.calcOpKey,
    required this.swatchBorder,
  });

  final Brightness brightness;
  final Color bg;
  final Color bgElevated;
  final Color bgCard;

  /// Accent for text/icons on [bg] (mint in dark, deep green in light).
  final Color accent;
  final Color accentDim;

  /// Text/icons drawn on an [accent] fill (`=` key, buttons, FAB).
  final Color onAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color danger;
  final Color warning;

  /// Calculator digit keys and operator keys.
  final Color calcKey;
  final Color calcOpKey;

  /// Unselected wallpaper swatch outline in Settings.
  final Color swatchBorder;

  static const GizliColors dark = GizliColors(
    brightness: Brightness.dark,
    bg: GizliTheme.bg,
    bgElevated: GizliTheme.bgElevated,
    bgCard: GizliTheme.bgCard,
    accent: GizliTheme.mint,
    accentDim: GizliTheme.mintDim,
    onAccent: GizliTheme.bg,
    textPrimary: GizliTheme.textPrimary,
    textSecondary: GizliTheme.textSecondary,
    danger: GizliTheme.danger,
    warning: GizliTheme.warning,
    calcKey: GizliTheme.bgCard,
    calcOpKey: GizliTheme.bgElevated,
    swatchBorder: Color(0x3DFFFFFF),
  );

  /// Contrast on [bg] #F4F6FA (WCAG): textPrimary ~17:1, textSecondary
  /// ~7:1, accent ~5:1, danger ~5:1, warning ~5:1; white on accent ~5.3:1.
  static const GizliColors light = GizliColors(
    brightness: Brightness.light,
    bg: Color(0xFFF4F6FA),
    bgElevated: Color(0xFFFFFFFF),
    bgCard: Color(0xFFFFFFFF),
    accent: Color(0xFF0A7A4A),
    accentDim: Color(0xFF3D9A6C),
    onAccent: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0B1220),
    textSecondary: Color(0xFF4A5568),
    danger: Color(0xFFC62828),
    warning: Color(0xFF8A5A00),
    calcKey: Color(0xFFE6EAF0),
    calcOpKey: Color(0xFFD6EFE1),
    swatchBorder: Color(0x42000000),
  );

  /// Colours of the current theme (dark palette if none is installed).
  static GizliColors of(BuildContext context) =>
      Theme.of(context).extension<GizliColors>() ?? dark;

  @override
  GizliColors copyWith() => this;

  @override
  GizliColors lerp(ThemeExtension<GizliColors>? other, double t) {
    if (other is! GizliColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return GizliColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: l(bg, other.bg),
      bgElevated: l(bgElevated, other.bgElevated),
      bgCard: l(bgCard, other.bgCard),
      accent: l(accent, other.accent),
      accentDim: l(accentDim, other.accentDim),
      onAccent: l(onAccent, other.onAccent),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      danger: l(danger, other.danger),
      warning: l(warning, other.warning),
      calcKey: l(calcKey, other.calcKey),
      calcOpKey: l(calcOpKey, other.calcOpKey),
      swatchBorder: l(swatchBorder, other.swatchBorder),
    );
  }
}
