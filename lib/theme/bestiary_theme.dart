import 'package:flutter/material.dart';

abstract final class BestiaryPalette {
  static const paper = Color(0xFFF2EEE3);
  static const page = Color(0xFFFCFAF4);
  static const ink = Color(0xFF26382D);
  static const forest = Color(0xFF334C3B);
  static const moss = Color(0xFF74836A);
  static const sage = Color(0xFFE4E9DD);
  static const line = Color(0xFFDED8C9);
  static const mutedInk = Color(0xFF6E756A);
  static const brass = Color(0xFFB18A53);
  static const rust = Color(0xFFA65F43);
}

abstract final class BestiaryTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: BestiaryPalette.forest,
      brightness: Brightness.light,
      surface: BestiaryPalette.page,
      primary: BestiaryPalette.forest,
      secondary: BestiaryPalette.moss,
      tertiary: BestiaryPalette.rust,
      outline: BestiaryPalette.line,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: BestiaryPalette.paper,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'serif',
          fontSize: 42,
          height: 1.04,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.3,
          color: BestiaryPalette.ink,
        ),
        displayMedium: TextStyle(
          fontFamily: 'serif',
          fontSize: 34,
          height: 1.08,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.8,
          color: BestiaryPalette.ink,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'serif',
          fontSize: 25,
          height: 1.12,
          fontWeight: FontWeight.w600,
          color: BestiaryPalette.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: BestiaryPalette.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: BestiaryPalette.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: BestiaryPalette.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: BestiaryPalette.ink,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: BestiaryPalette.mutedInk,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: BestiaryPalette.mutedInk,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BestiaryPalette.paper,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'serif',
          color: BestiaryPalette.ink,
          fontSize: 21,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: BestiaryPalette.forest),
      ),
      cardTheme: CardThemeData(
        color: BestiaryPalette.page,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: BestiaryPalette.line),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: BestiaryPalette.line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BestiaryPalette.page,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BestiaryPalette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BestiaryPalette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BestiaryPalette.forest, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BestiaryPalette.page,
        surfaceTintColor: Colors.transparent,
        indicatorColor: BestiaryPalette.sage,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BestiaryPalette.page,
        selectedColor: BestiaryPalette.sage,
        side: const BorderSide(color: BestiaryPalette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        labelStyle: const TextStyle(
          color: BestiaryPalette.ink,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BestiaryPalette.forest,
          foregroundColor: BestiaryPalette.page,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BestiaryPalette.ink,
      ),
    );
  }
}
