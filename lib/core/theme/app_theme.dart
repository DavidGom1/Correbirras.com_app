import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// ==================== COLORES PRINCIPALES DE LA MARCA ====================
final Color correbirrasOrange = Color.fromRGBO(239, 120, 26, 1);
final Color correbirrasOrangeDark = Color.fromRGBO(200, 100, 20, 1);
final Color correbirrasOrangeSoft = Color.fromRGBO(
  180,
  90,
  20,
  1,
); // Color más suave para tema oscuro

// ==================== COLORES PARA TEMA CLARO ====================
final Color lightBackground = Color(0xFFf9f9f9);
final Color lightSurface = Colors.white;
final Color lightCardBackground = Colors.white;

// ==================== COLORES PARA TEMA OSCURO ====================
final Color darkBackground = Color(0xFF1A1A1A); // Gris menos oscuro para fondo
final Color darkSurface = Color(0xFF2A2A2A); // Gris para drawer y app
final Color darkCardBackground = Color(
  0xFF4A4A4A,
); // Gris más claro para racecards (mejor contraste)
final Color darkPrimary = Color(
  0xFF2A2A2A,
); // Gris para AppBar y elementos principales

// ==================== COLORES ESPECÍFICOS PARA COMPONENTES ====================

// 🏃‍♂️ RACE CARDS
class RaceCardColors {
  // Tema claro
  static const Color lightBackground = Colors.white;
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightText = Colors.black87;
  static const Color lightSubtext = Colors.black54;

  // Tema oscuro
  static const Color darkBackground = Color.fromARGB(
    255,
    52,
    52,
    52,
  ); // Más claro para mejor contraste
  static const Color darkBorder = Color(0xFF5A5A5A);
  static const Color darkText = Colors.white;
  static const Color darkSubtext = Color(0xFFB0B0B0);
}

// ❤️ FAVORITOS (CORAZONES)
class FavoriteColors {
  // Estados del corazón
  static const Color liked = Color.fromRGBO(
    239,
    120,
    26,
    1,
  ); // Rosa/rojo para favorito activo
  static const Color unliked = Color(0xFF9E9E9E); // Gris para favorito inactivo

  // Tema claro
  static const Color lightIcon = Color(0xFF9E9E9E);
  static const Color lightIconActive = Color.fromRGBO(239, 120, 26, 1);

  // Tema oscuro
  static const Color darkIcon = Color(0xFF707070);
  static const Color darkIconActive = Color.fromARGB(255, 150, 150, 150);
}

// 🎛️ CONTROLES Y BOTONES
class ControlColors {
  // Tema claro
  static final Color lightPrimary = correbirrasOrange;
  static const Color lightSecondary = Color(0xFF6C757D);
  static const Color lightButton = Color(0xFFf8f9fa);
  static const Color lightButtonText = Colors.black87;

  // Tema oscuro
  static const Color darkPrimary = Color(
    0xFF2A2A2A,
  ); // Gris en lugar de naranja
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
  static const Color darkSliderActive = Color(
    0xFF505050,
  ); // Gris en lugar de naranja
  static const Color darkSliderInactive = Color(0xFF404040);
}

class AppTheme {
  // ==================== TEMA CLARO ====================
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: correbirrasOrange,
      brightness: Brightness.light,
    ).copyWith(primary: correbirrasOrange, surface: lightSurface),
    scaffoldBackgroundColor: lightBackground,
    cardColor:
        RaceCardColors.lightBackground, // Usando color específico para cards
    appBarTheme: AppBarTheme(
      backgroundColor: correbirrasOrange,
      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
      elevation: 0,
      shadowColor: Color.fromARGB(186, 0, 0, 0),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: lightSurface),
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
    iconTheme: IconThemeData(color: Colors.black54),
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
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: darkPrimary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: darkPrimary,
          surface: darkSurface,
          onSurface: Colors.white,
        ),
    scaffoldBackgroundColor: darkBackground,
    cardColor:
        RaceCardColors.darkBackground, // Usando color específico para cards
    appBarTheme: AppBarTheme(
      backgroundColor: darkPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Color.fromARGB(186, 0, 0, 0),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: darkSurface),
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
    iconTheme: IconThemeData(color: Colors.white70),
    // Configuración de sliders para tema oscuro
    sliderTheme: SliderThemeData(
      activeTrackColor: FilterColors.darkSliderActive,
      inactiveTrackColor: FilterColors.darkSliderInactive,
      thumbColor: FilterColors.darkSliderActive,
    ),
    useMaterial3: true,
  );

  // ==================== MÉTODOS DE ACCESO CENTRALIZADOS ====================

  // 📱 BACKGROUNDS Y SUPERFICIES
  static Color getScaffoldBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardBackground
        : lightCardBackground;
  }

  // 🏃‍♂️ RACE CARDS
  static Color getRaceCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? RaceCardColors.darkBackground
        : const Color.fromARGB(
            255,
            238,
            233,
            228,
          ); // Color más claro para mejor contraste
  }

  static Color getRaceCardShadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(255, 0, 0, 0)
        : const Color.fromARGB(255, 190, 190, 190).withValues(alpha: 0.9);
  }

  static Color getRaceCardBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? RaceCardColors.darkBorder
        : RaceCardColors.lightBorder;
  }

  static Color getRaceCardText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? RaceCardColors.darkText
        : RaceCardColors.lightText;
  }

  static Color getRaceCardSubtext(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? RaceCardColors.darkSubtext
        : RaceCardColors.lightSubtext;
  }

  // ❤️ FAVORITOS
  static Color getFavoriteIcon(BuildContext context, {bool isActive = false}) {
    if (isActive) {
      return Theme.of(context).brightness == Brightness.dark
          ? FavoriteColors.darkIconActive
          : FavoriteColors.lightIconActive;
    }
    return Theme.of(context).brightness == Brightness.dark
        ? FavoriteColors.darkIcon
        : FavoriteColors.lightIcon;
  }

  // 🎛️ CONTROLES Y BOTONES
  static Color getPrimaryControlColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? ControlColors.darkPrimary
        : ControlColors.lightPrimary;
  }

  static Color getSecondaryControlColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? ControlColors.darkSecondary
        : ControlColors.lightSecondary;
  }

  static Color getButtonColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? ControlColors.darkButton
        : ControlColors.lightButton;
  }

  static Color getButtonTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? ControlColors.darkButtonText
        : ControlColors.lightButtonText;
  }

  // 🔍 FILTROS Y SLIDERS
  static Color getSliderActiveColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? FilterColors.darkSliderActive
        : FilterColors.lightSliderActive;
  }

  static Color getSliderInactiveColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? FilterColors.darkSliderInactive
        : FilterColors.lightSliderInactive;
  }

  // 🎨 COLORES DE MARCA Y PRINCIPALES
  static Color getBrandOrange(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? correbirrasOrangeSoft // Versión más suave para tema oscuro
        : correbirrasOrange;
  }

  static Color getBrandOrangeDark(BuildContext context) {
    return correbirrasOrangeDark; // Se mantiene igual en ambos temas
  }

  // 📝 TEXTOS
  static Color getPrimaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(199, 255, 255, 255)
        : const Color.fromARGB(232, 255, 255, 255);
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(136, 255, 255, 255)
        : const Color.fromARGB(154, 255, 255, 255);
  }

  // 🔲 ICONOS
  static Color getPrimaryIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
  }

  static Color getSecondaryIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black38;
  }

  // 🎨 DRAWER ESPECÍFICOS
  static Color getDrawerSocialIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors
              .white54 // Más suave en oscuro
        : getBrandOrange(context);
  }

  static Color getDrawerHeaderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Color.fromARGB(255, 66, 66, 66) // Color específico para header oscuro
        : correbirrasOrange; // Color específico para header claro
  }

  static Color getDrawerTextDevColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors
              .white70 // Más suave en oscuro
        : const Color.fromARGB(221, 93, 93, 93); // Más oscuro en claro
  }

  static LinearGradient getDrawerDividerGradient(BuildContext context) {
    final baseColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white54.withValues(alpha: 0.6) // Más suave en oscuro
        : getBrandOrange(context);

    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        baseColor.withValues(alpha: 0.3),
        baseColor.withValues(alpha: 0.7),
        baseColor.withValues(alpha: 0.3),
        Colors.transparent,
      ],
    );
  }

  static Color getDrawerButtonBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(154, 255, 255, 255).withValues(
            alpha: 0.2,
          ) // Más suave en oscuro
        : getBrandOrange(context).withValues(alpha: 0.4);
  }

  static Color getDialogBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Color(0xFF2A2A2A) // Mismo color que darkSurface para consistencia
        : Colors.white;
  }

  // 🧩 MÉTODOS DE COMPATIBILIDAD (mantienen la funcionalidad anterior)
  @Deprecated('Use getFavoriteIcon(context, isActive: bool) instead')
  static Color getFavoriteColor(BuildContext context, bool isActive) {
    return getFavoriteIcon(context, isActive: isActive);
  }

  // SPINNER PARA LA WEB
  static getSpinKitPumpingHeart(BuildContext context) {
    return SpinKitPumpingHeart(
      //con color semitransparente
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white70
          : correbirrasOrange,
      size: 55.0,
    );
  }

  // Estilo de texto para campos de entrada
  static TextStyle getInputTextStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color.fromARGB(255, 164, 164, 164)
          : const Color.fromARGB(221, 66, 66, 66),
      fontSize: 16,
    );
  }

  // Color personalizado para labels
  static TextStyle getLabelTextStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color.fromARGB(255, 164, 164, 164)
          : const Color.fromARGB(221, 66, 66, 66),
      fontSize: 16,
    );
  }

  @Deprecated('Use getPrimaryControlColor(context) instead')
  static Color getControlColor(BuildContext context) {
    return getPrimaryControlColor(context);
  }

  // Método de conveniencia para el tema actual (será usado por el provider)
  static ThemeData theme = lightTheme;
}

// ==================== UTILIDADES AVANZADAS DE TEMA ====================
class ThemeUtils {
  // 🎯 DETECTORES DE TEMA
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static bool isLightMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light;
  }

  // 🎨 GENERADORES DE COLORES DINÁMICOS
  static Color getAdaptiveColor(
    BuildContext context,
    Color lightColor,
    Color darkColor,
  ) {
    return isDarkMode(context) ? darkColor : lightColor;
  }

  // Color con opacidad adaptativa
  static Color getAdaptiveColorWithOpacity(
    BuildContext context,
    Color lightColor,
    Color darkColor,
    double opacity,
  ) {
    return getAdaptiveColor(
      context,
      lightColor,
      darkColor,
    ).withValues(alpha: opacity);
  }

  // 🎭 SOMBRAS ADAPTATIVAS
  static BoxShadow getAdaptiveShadow(BuildContext context) {
    return BoxShadow(
      color: isDarkMode(context)
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.grey.withValues(alpha: 0.2),
      spreadRadius: 1,
      blurRadius: 5,
      offset: Offset(0, 2),
    );
  }

  static List<BoxShadow> getAdaptiveCardShadow(BuildContext context) {
    return [
      BoxShadow(
        color: isDarkMode(context)
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.grey.withValues(alpha: 0.15),
        spreadRadius: 0,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ];
  }

  // 🎯 COLORES ESPECÍFICOS PARA ESTADOS
  static Color getSuccessColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      Color(0xFF4CAF50), // Verde claro
      Color(0xFF66BB6A), // Verde más claro para dark
    );
  }

  static Color getWarningColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      Color(0xFFFF9800), // Naranja claro
      Color(0xFFFFB74D), // Naranja más claro para dark
    );
  }

  static Color getErrorColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      Color(0xFFF44336), // Rojo claro
      Color(0xFFEF5350), // Rojo más claro para dark
    );
  }

  static Color getInfoColor(BuildContext context) {
    return getAdaptiveColor(
      context,
      Color(0xFF2196F3), // Azul claro
      Color(0xFF42A5F5), // Azul más claro para dark
    );
  }

  // 🎨 GRADIENTES ADAPTATIVOS
  static LinearGradient getAdaptiveGradient(BuildContext context) {
    return LinearGradient(
      colors: isDarkMode(context)
          ? [darkBackground, darkSurface]
          : [lightBackground, lightSurface],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient getCardGradient(BuildContext context) {
    return LinearGradient(
      colors: isDarkMode(context)
          ? [RaceCardColors.darkBackground, Color(0xFF555555)]
          : [RaceCardColors.lightBackground, Color(0xFFFAFAFA)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  // 🎯 CONFIGURACIONES DE COMPONENTES ESPECÍFICOS
  static TextStyle getAdaptiveTextStyle(
    BuildContext context, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    bool isPrimary = true,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: isPrimary
          ? AppTheme.getPrimaryTextColor(context)
          : AppTheme.getSecondaryTextColor(context),
    );
  }

  static InputDecoration getAdaptiveInputDecoration(
    BuildContext context,
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppTheme.getSecondaryIconColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppTheme.getPrimaryControlColor(context)),
      ),
      filled: true,
      fillColor: AppTheme.getCardBackground(context),
    );
  }
}
