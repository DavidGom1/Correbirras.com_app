import 'package:flutter/material.dart';

// ==================== COLORES PRINCIPALES DE LA MARCA ====================
final Color correbirrasOrange = Color.fromRGBO(239, 120, 26, 1);
final Color correbirrasOrangeDark = Color.fromRGBO(200, 100, 20, 1);
final Color correbirrasOrangeSoft = Color.fromRGBO(180, 90, 20, 1); // Color más suave para tema oscuro

// ==================== COLORES PARA TEMA CLARO ====================
final Color lightBackground = Color(0xFFf9f9f9);
final Color lightSurface = Colors.white;
final Color lightCardBackground = Colors.white;

// ==================== COLORES PARA TEMA OSCURO ====================
final Color darkBackground = Color(0xFF1A1A1A); // Gris menos oscuro para fondo
final Color darkSurface = Color(0xFF2A2A2A); // Gris para drawer y app
final Color darkCardBackground = Color(0xFF4A4A4A); // Gris más claro para racecards (mejor contraste)
final Color darkPrimary = Color(0xFF2A2A2A); // Gris para AppBar y elementos principales

// ==================== COLORES ESPECÍFICOS PARA COMPONENTES ====================

// 🏃‍♂️ RACE CARDS
class RaceCardColors {
  // Tema claro
  static const Color lightBackground = Colors.white;
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightText = Colors.black87;
  static const Color lightSubtext = Colors.black54;
  
  // Tema oscuro
  static const Color darkBackground = Color(0xFF4A4A4A); // Más claro para mejor contraste
  static const Color darkBorder = Color(0xFF5A5A5A);
  static const Color darkText = Colors.white;
  static const Color darkSubtext = Color(0xFFB0B0B0);
}

// ❤️ FAVORITOS (CORAZONES)
class FavoriteColors {
  // Estados del corazón
  static const Color liked = Color(0xFFE91E63); // Rosa/rojo para favorito activo
  static const Color unliked = Color(0xFF9E9E9E); // Gris para favorito inactivo
  
  // Tema claro
  static const Color lightIcon = Color(0xFF9E9E9E);
  static const Color lightIconActive = Color(0xFFE91E63);
  
  // Tema oscuro
  static const Color darkIcon = Color(0xFF707070);
  static const Color darkIconActive = Color(0xFFE91E63);
}

// 🎛️ CONTROLES Y BOTONES
class ControlColors {
  // Tema claro
  static final Color lightPrimary = correbirrasOrange;
  static const Color lightSecondary = Color(0xFF6C757D);
  static const Color lightButton = Color(0xFFf8f9fa);
  static const Color lightButtonText = Colors.black87;
  
  // Tema oscuro
  static const Color darkPrimary = Color(0xFF2A2A2A); // Gris en lugar de naranja
  static const Color darkSecondary = Color(0xFF505050);
  static const Color darkButton = Color(0xFF3A3A3A);
  static const Color darkButtonText = Colors.white;
}

// 🔍 FILTROS Y SLIDERS
class FilterColors {
  // Tema claro
  static final Color lightSliderActive = correbirrasOrange;
  static const Color lightSliderInactive = Color(0xFFE0E0E0);
  
  // Tema oscuro
  static const Color darkSliderActive = Color(0xFF505050); // Gris en lugar de naranja
  static const Color darkSliderInactive = Color(0xFF404040);
}

class AppTheme {
  // ==================== TEMA CLARO ====================
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
    cardColor: RaceCardColors.lightBackground, // Usando color específico para cards
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
      bodyLarge: TextStyle(color: RaceCardColors.lightText),
      bodyMedium: TextStyle(color: RaceCardColors.lightText),
      titleLarge: TextStyle(color: RaceCardColors.lightText),
      titleMedium: TextStyle(color: RaceCardColors.lightText),
      labelLarge: TextStyle(color: Colors.white),
    ),
    iconTheme: IconThemeData(
      color: Colors.black54,
    ),
    // Configuración de sliders para tema claro
    sliderTheme: SliderThemeData(
      activeTrackColor: FilterColors.lightSliderActive,
      inactiveTrackColor: FilterColors.lightSliderInactive,
      thumbColor: FilterColors.lightSliderActive,
    ),
    useMaterial3: true,
  );

  // ==================== TEMA OSCURO ====================
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: darkPrimary,
      surface: darkSurface,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: darkBackground,
    cardColor: RaceCardColors.darkBackground, // Usando color específico para cards
    appBarTheme: AppBarTheme(
      backgroundColor: darkPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Color.fromARGB(186, 0, 0, 0),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: darkSurface,
    ),
    listTileTheme: ListTileThemeData(
      textColor: RaceCardColors.darkText,
      iconColor: Colors.white70,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: RaceCardColors.darkText),
      bodyMedium: TextStyle(color: RaceCardColors.darkText),
      titleLarge: TextStyle(color: RaceCardColors.darkText),
      titleMedium: TextStyle(color: RaceCardColors.darkText),
      labelLarge: TextStyle(color: Colors.white),
    ),
    iconTheme: IconThemeData(
      color: Colors.white70,
    ),
    // Configuración de sliders para tema oscuro
    sliderTheme: SliderThemeData(
      activeTrackColor: FilterColors.darkSliderActive,
      inactiveTrackColor: FilterColors.darkSliderInactive,
      thumbColor: FilterColors.darkSliderActive,
    ),
    useMaterial3: true,
  );

  // ==================== MÉTODOS DE UTILIDAD ====================
  
  // Obtener color de race card según el tema
  static Color getRaceCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(255, 182, 0, 0)
        : RaceCardColors.lightBackground;
  }
  
  // Obtener color de texto de race card según el tema
  static Color getRaceCardText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? RaceCardColors.darkText
        : const Color.fromARGB(221, 0, 0, 0);
  }
  
  // Obtener color de favorito según el tema y estado
  static Color getFavoriteColor(BuildContext context, bool isActive) {
    if (isActive) {
      return Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(255, 74, 74, 74)
        : FavoriteColors.lightIcon;
    }
    return Theme.of(context).brightness == Brightness.dark
        ? FavoriteColors.darkIcon
        : FavoriteColors.lightIcon;
  }
  
  // Obtener color de control según el tema
  static Color getControlColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? ControlColors.darkPrimary
        : ControlColors.lightPrimary;
  }
  
  // Método de conveniencia para el tema actual (será usado por el provider)
  static ThemeData theme = lightTheme;
}