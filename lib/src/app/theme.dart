import 'package:flutter/material.dart';

abstract final class PixelPalette {
  static const Color background = Color(0xFF071522);
  static const Color surface = Color(0xFF10202D);
  static const Color surfaceRaised = Color(0xFF172A36);
  static const Color line = Color(0xFF34434B);
  static const Color cream = Color(0xFFE9DCC3);
  static const Color muted = Color(0xFFA6A99F);
  static const Color mint = Color(0xFF77C9B4);
  static const Color amber = Color(0xFFD6A657);
  static const Color blue = Color(0xFF72AEDD);
  static const Color violet = Color(0xFF9B7AD1);
  static const Color danger = Color(0xFFE57C5C);
  static const Color success = Color(0xFF7FC692);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: PixelPalette.mint,
    brightness: Brightness.dark,
    surface: PixelPalette.surface,
  ).copyWith(
    primary: PixelPalette.mint,
    secondary: PixelPalette.amber,
    error: PixelPalette.danger,
    onSurface: PixelPalette.cream,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: PixelPalette.background,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: PixelPalette.cream,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineSmall: TextStyle(
        color: PixelPalette.cream,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: PixelPalette.cream,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: PixelPalette.cream,
        fontSize: 16,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        color: PixelPalette.muted,
        fontSize: 14,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        color: PixelPalette.cream,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: PixelPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: PixelPalette.line),
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: PixelPalette.background,
      foregroundColor: PixelPalette.cream,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 74,
      backgroundColor: PixelPalette.surface,
      indicatorColor: PixelPalette.mint.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? PixelPalette.mint
              : PixelPalette.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: PixelPalette.mint,
        foregroundColor: PixelPalette.background,
        minimumSize: const Size(44, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PixelPalette.cream,
        minimumSize: const Size(44, 52),
        side: const BorderSide(color: PixelPalette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: PixelPalette.surfaceRaised,
      contentTextStyle: TextStyle(color: PixelPalette.cream),
    ),
  );
}
