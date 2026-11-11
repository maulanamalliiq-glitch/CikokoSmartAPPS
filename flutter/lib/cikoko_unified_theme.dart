import 'package:flutter/material.dart';

/// Sistem desain tunggal Cikoko Smart untuk seluruh halaman Flutter.
/// Hanya mengubah tampilan, tanpa mengubah login, API, dan izin akses.
abstract final class CikokoPalette {
  static const navy = Color(0xFF082D5E);
  static const dark = Color(0xFF031D43);
  static const blue = Color(0xFF216CDD);
  static const surface = Colors.white;
  static const background = Color(0xFFF3F7FD);
  static const soft = Color(0xFFEAF3FF);
  static const muted = Color(0xFF627B96);
  static const border = Color(0xFFDBE6F3);
}

ThemeData cikokoUnifiedTheme() {
  const blue = CikokoPalette.blue;
  const navy = CikokoPalette.navy;
  const border = CikokoPalette.border;
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: const BorderSide(color: border),
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: const BorderSide(color: border),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: CikokoPalette.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: blue,
      primary: blue,
      surface: CikokoPalette.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: CikokoPalette.surface,
      foregroundColor: navy,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 64,
      titleSpacing: 15,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: navy, fontSize: 17, fontWeight: FontWeight.w800),
      iconTheme: IconThemeData(color: navy),
    ),
    cardTheme: CardThemeData(
      color: CikokoPalette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
      shape: rounded,
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: CikokoPalette.surface,
      labelStyle: const TextStyle(fontSize: 13, color: navy),
      hintStyle: const TextStyle(fontSize: 12, color: CikokoPalette.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: blue, width: 1.6)),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFFD93654))),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: blue, foregroundColor: Colors.white,
        minimumSize: const Size(0, 42),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        minimumSize: const Size(0, 42),
        side: const BorderSide(color: border),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 65,
      backgroundColor: CikokoPalette.surface,
      indicatorColor: CikokoPalette.soft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 11, color: navy, fontWeight: FontWeight.w700)),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: navy, size: 23)),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: CikokoPalette.surface,
      elevation: 0,
    ),
    listTileTheme: const ListTileThemeData(
      textColor: navy,
      iconColor: blue,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      dense: true,
    ),
    dividerTheme: const DividerThemeData(
      color: border, space: 1, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: CikokoPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: CikokoPalette.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 22, color: navy, fontWeight: FontWeight.w850),
      titleLarge: TextStyle(fontSize: 19, color: navy, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(fontSize: 15, color: navy, fontWeight: FontWeight.w750),
      bodyLarge: TextStyle(fontSize: 14, color: navy),
      bodyMedium: TextStyle(fontSize: 13, color: navy),
      bodySmall: TextStyle(fontSize: 12, color: CikokoPalette.muted),
    ),
  );
}
