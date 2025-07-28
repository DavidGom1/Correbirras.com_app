import 'package:flutter/material.dart';

// Colores principales de la marca
final Color correbirrasOrange = Color.fromRGBO(239, 120, 26, 1);
final Color correbirrasOrangeDark = Color.fromRGBO(200, 100, 20, 1);
final Color correbirrasOrangeSoft = Color.fromRGBO(180, 90, 20, 1); // Color más suave para tema oscuro

// Colores para tema claro
final Color lightBackground = Color(0xFFf9f9f9);
final Color lightSurface = Colors.white;
final Color lightCardBackground = Colors.white;

// Colores para tema oscuro
final Color darkBackground = Color(0xFF121212);
final Color darkSurface = Color(0xFF1E1E1E);
final Color darkCardBackground = Color(0xFF2D2D2D);

class AppTheme {
  // Tema claro
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: correbirrasOrange,
      brightness: Brightness.light,
    ).copyWith(
      primary: correbirrasOrange,
      surface: lightSurface,
    ),
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightCardBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: correbirrasOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Color.fromARGB(186, 0, 0, 0),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: lightSurface,
    ),
    listTileTheme: ListTileThemeData(
      textColor: Colors.black87,
      iconColor: Colors.black54,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black87),
      labelLarge: TextStyle(color: Colors.white),
    ),
    iconTheme: IconThemeData(
      color: Colors.black54,
    ),
    useMaterial3: true,
  );

  // Tema oscuro
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: correbirrasOrangeSoft,
      brightness: Brightness.dark,
    ).copyWith(
      primary: correbirrasOrangeSoft,
      surface: darkSurface,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCardBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: correbirrasOrangeSoft,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Color.fromARGB(186, 0, 0, 0),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: darkSurface,
    ),
    listTileTheme: ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white70,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      labelLarge: TextStyle(color: Colors.white),
    ),
    iconTheme: IconThemeData(
      color: Colors.white70,
    ),
    useMaterial3: true,
  );

  // Método de conveniencia para el tema actual (será usado por el provider)
  static ThemeData theme = lightTheme;
}
