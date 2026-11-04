import 'package:flutter/material.dart';

/// Shared premium minimalist design system for every Material page.
/// This layer changes appearance only; routes, APIs and permissions remain intact.
abstract final class CikokoDesign {
  static const navy = Color(0xFF102A56);
  static const royal = Color(0xFF1769D2);
  static const gold = Color(0xFFF2B84B);
  static const canvas = Color(0xFFF6F8FC);
  static const ink = Color(0xFF182C47);
  static const muted = Color(0xFF64748B);
  static const outline = Color(0xFFE4EAF2);
  static const radius = 20.0;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: royal,
      brightness: Brightness.light,
      primary: royal,
      secondary: gold,
      surface: Colors.white,
      onSurface: ink,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: outline, width: .7),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      primaryColor: royal,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 19, fontWeight: FontWeight.w700, color: navy,
          letterSpacing: -.35,
        ),
        iconTheme: IconThemeData(color: navy),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: muted, fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: royal, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: royal,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: royal,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFE6F0FF),
        side: const BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: ink),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: royal,
        textColor: ink,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: .8),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: royal,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFE6F0FF),
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? royal : muted,
        )),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: royal, foregroundColor: Colors.white, elevation: 2,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: navy, letterSpacing: -.5),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: navy, letterSpacing: -.3),
        titleMedium: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: navy),
        bodyLarge: TextStyle(fontSize: 15, color: ink, height: 1.45),
        bodyMedium: TextStyle(fontSize: 13.5, color: ink, height: 1.45),
        bodySmall: TextStyle(fontSize: 12, color: muted, height: 1.4),
      ),
    );
  }
}
