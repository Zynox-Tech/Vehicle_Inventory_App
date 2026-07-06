import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color darkBg = Color(0xFF0D0D0D); // near black
  static const Color darkSurface = Color.fromRGBO(26, 26, 26, 1);
  static const Color accentOrange = Color(0xFFFF7A00);
  static const Color accentOrangeDark = Color(0xFFCC6300);
  static const Color textWhite = Colors.white;
  static const Color dangerRed = Color(0xFFFF3B30);
  static const Color successGreen = Color(0xFF34C759);

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      colorScheme: base.colorScheme.copyWith(
        primary: accentOrange,
        secondary: accentOrangeDark,
        surface: darkSurface,
        background: darkBg,
        onPrimary: textWhite,
        onSecondary: textWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: textWhite,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentOrange),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentOrange),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentOrange,
        foregroundColor: textWhite,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
