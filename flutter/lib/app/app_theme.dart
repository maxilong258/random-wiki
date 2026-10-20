import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark
        ? const ColorScheme.dark(
            primary: Color(0xfff5f5f5),
            onPrimary: Color(0xff151515),
            secondary: Color(0xfff5f5f5),
            surface: Color(0xff151515),
            onSurface: Color(0xfff5f5f5),
            surfaceContainerHighest: Color(0xff282828),
            outlineVariant: Color(0xff454545),
          )
        : const ColorScheme.light(
            primary: Color(0xff161616),
            onPrimary: Colors.white,
            secondary: Color(0xff161616),
            surface: Color(0xfffdfdfd),
            onSurface: Color(0xff161616),
            surfaceContainerHighest: Color(0xffeeeeee),
            outlineVariant: Color(0xffe0e0e0),
          );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xff151515)
          : const Color(0xfffdfdfd),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.copyWith(
        displaySmall: TextStyle(
          fontSize: 32,
          height: 1.12,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
        bodyLarge: TextStyle(fontSize: 17, color: scheme.onSurface),
        labelMedium: TextStyle(
          letterSpacing: 0.4,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
