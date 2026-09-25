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
      cardTheme: CardTheme(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
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
