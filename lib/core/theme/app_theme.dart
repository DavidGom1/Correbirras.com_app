import 'package:flutter/material.dart';

final Color correbirrasOrange = Color.fromRGBO(239, 120, 26, 1);
final Color correbirrasBackground = Color(0xFFf9f9f9);

class AppTheme {
  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: correbirrasOrange),
    scaffoldBackgroundColor: correbirrasBackground,
    useMaterial3: true,
  );
}
