import 'package:flutter/material.dart';

/// Bright, lively colours - one per section of the app.
class Palette {
  static const firstAid = [Color(0xFFFF5252), Color(0xFFFF8A65)];
  static const maps = [Color(0xFF2979FF), Color(0xFF00B0FF)];
  static const library = [Color(0xFF7C4DFF), Color(0xFFB388FF)];
  static const radio = [Color(0xFFFF9100), Color(0xFFFFC400)];
  static const chat = [Color(0xFF00BFA5), Color(0xFF1DE9B6)];
  static const updates = [Color(0xFF43A047), Color(0xFF9CCC65)];
  static const sos = [Color(0xFFD50000), Color(0xFFFF1744)];

  /// Colours used to tint library categories.
  static const category = [
    Color(0xFFFF5252),
    Color(0xFF2979FF),
    Color(0xFF7C4DFF),
    Color(0xFFFF9100),
    Color(0xFF00BFA5),
    Color(0xFF43A047),
    Color(0xFFEC407A),
    Color(0xFF26C6DA),
  ];
}

LinearGradient gradientOf(List<Color> c) => LinearGradient(
      colors: c,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

ThemeData buildTheme(Brightness b) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00BFA5),
    brightness: b,
  );
  final light = b == Brightness.light;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        light ? const Color(0xFFF4FBFA) : const Color(0xFF0E1514),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: light ? const Color(0xFF00BFA5) : const Color(0xFF00695C),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
