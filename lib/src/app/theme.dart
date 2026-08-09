import 'package:flutter/material.dart';

abstract final class PixelPalette {
  // Night Cabinet: the shell stays quiet so the authored diorama art carries
  // the product identity. Legacy names remain as semantic aliases while the
  // UI migrates screen by screen.
  static const Color canvas = Color(0xFF06131D);
  static const Color scene = Color(0xFF081822);
  static const Color panel = Color(0xFF0F202A);
  static const Color raised = Color(0xFF152A34);
  static const Color divider = Color(0xFF2A3B42);
  static const Color textStrong = Color(0xFFF2E6CE);
  static const Color textBody = Color(0xFFCAD0C5);
  static const Color textMuted = Color(0xFF929C94);
  static const Color action = Color(0xFF78CBB5);
  static const Color actionInk = Color(0xFF061A16);
  static const Color reward = Color(0xFFD9AA55);
  static const Color weather = Color(0xFF77AED5);
  static const Color visitor = Color(0xFF9A83CB);
  static const Color danger = Color(0xFFDF7A61);
  static const Color focus = Color(0xFF98D8C8);

  static const Color background = canvas;
  static const Color surface = panel;
  static const Color surfaceRaised = raised;
  static const Color line = divider;
  static const Color cream = textStrong;
  static const Color muted = textMuted;
  static const Color mint = action;
  static const Color amber = reward;
  static const Color blue = weather;
  static const Color violet = visitor;
  static const Color success = action;
}

abstract final class PixelRadii {
  static const double scene = 18;
  static const double tray = 14;
  static const double card = 10;
  static const double tile = 8;
  static const double chip = 6;
  static const double control = 10;
}

abstract final class PixelSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
}

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: PixelPalette.action,
        brightness: Brightness.dark,
        surface: PixelPalette.panel,
      ).copyWith(
        primary: PixelPalette.action,
        onPrimary: PixelPalette.actionInk,
        secondary: PixelPalette.reward,
        error: PixelPalette.danger,
        surface: PixelPalette.panel,
        onSurface: PixelPalette.textStrong,
        outline: PixelPalette.divider,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: PixelPalette.background,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: PixelPalette.textStrong,
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: TextStyle(
        color: PixelPalette.textStrong,
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: PixelPalette.textStrong,
        fontSize: 17,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: PixelPalette.textBody,
        fontSize: 15,
        height: 1.47,
      ),
      bodyMedium: TextStyle(
        color: PixelPalette.textMuted,
        fontSize: 13,
        height: 1.38,
      ),
      labelLarge: TextStyle(
        color: PixelPalette.textStrong,
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: PixelPalette.panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PixelRadii.card),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: PixelPalette.canvas,
      foregroundColor: PixelPalette.textStrong,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 74,
      backgroundColor: PixelPalette.panel,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((
        Set<WidgetState> states,
      ) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? PixelPalette.action
              : PixelPalette.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: PixelPalette.action,
        foregroundColor: PixelPalette.actionInk,
        minimumSize: const Size(44, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PixelRadii.control),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PixelPalette.textStrong,
        minimumSize: const Size(44, 48),
        side: const BorderSide(color: PixelPalette.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PixelRadii.control),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: PixelPalette.raised,
      contentTextStyle: TextStyle(color: PixelPalette.textStrong),
    ),
    dividerTheme: const DividerThemeData(
      color: PixelPalette.divider,
      thickness: 1,
      space: 1,
    ),
    focusColor: PixelPalette.focus,
  );
}
