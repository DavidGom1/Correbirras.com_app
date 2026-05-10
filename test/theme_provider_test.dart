import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:correbirras/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider', () {
    test('Initial theme mode is system', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, AppThemeMode.system);
    });

    test('isDarkMode returns false for light', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(AppThemeMode.light);
      expect(provider.isDarkMode, false);
    });

    test('isDarkMode returns true for dark', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(AppThemeMode.dark);
      expect(provider.isDarkMode, true);
    });

    test('cycleTheme cycles through modes', () async {
      final provider = ThemeProvider();
      expect(provider.themeMode, AppThemeMode.system);
      provider.cycleTheme();
      expect(provider.themeMode, AppThemeMode.light);
      provider.cycleTheme();
      expect(provider.themeMode, AppThemeMode.dark);
      provider.cycleTheme();
      expect(provider.themeMode, AppThemeMode.system);
    });

    test('flutterThemeMode maps correctly', () async {
      final provider = ThemeProvider();
      
      await provider.setThemeMode(AppThemeMode.light);
      expect(provider.flutterThemeMode, ThemeMode.light);
      
      await provider.setThemeMode(AppThemeMode.dark);
      expect(provider.flutterThemeMode, ThemeMode.dark);
      
      await provider.setThemeMode(AppThemeMode.system);
      expect(provider.flutterThemeMode, ThemeMode.system);
    });

    test('themeModeLabel returns correct strings', () async {
      final provider = ThemeProvider();
      
      await provider.setThemeMode(AppThemeMode.light);
      expect(provider.themeModeLabel, 'Claro');
      
      await provider.setThemeMode(AppThemeMode.dark);
      expect(provider.themeModeLabel, 'Oscuro');
      
      await provider.setThemeMode(AppThemeMode.system);
      expect(provider.themeModeLabel, 'Sistema');
    });
  });
}