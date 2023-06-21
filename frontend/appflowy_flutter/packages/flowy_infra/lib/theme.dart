import 'package:flowy_infra/colorscheme/colorscheme.dart';
import 'package:flutter/material.dart';

class BuiltInTheme {
  static const String defaultTheme = 'Default';
  static const String dandelion = 'Dandelion';
  static const String lavender = 'Lavender';

  static const List<String> themes = [
    BuiltInTheme.defaultTheme,
    BuiltInTheme.dandelion,
    BuiltInTheme.lavender
  ];
}

class AppTheme {
  // metadata member
  final String themeName;
  final FlowyColorScheme lightTheme;
  final FlowyColorScheme darkTheme;
  // static final Map<String, dynamic> _cachedJsonData = {};
  static AppTheme get fallbackTheme =>  AppTheme(
    themeName: BuiltInTheme.defaultTheme,
    lightTheme: FlowyColorScheme.builtIn(BuiltInTheme.defaultTheme, Brightness.light),
    darkTheme: FlowyColorScheme.builtIn(BuiltInTheme.defaultTheme, Brightness.dark),
  );

  const AppTheme({
    required this.themeName,
    required this.lightTheme,
    required this.darkTheme,
  });

  factory AppTheme.fromName(String themeName) {
    if (!BuiltInTheme.themes.contains(themeName)) {
      return fallbackTheme;
    }
    return AppTheme(
      themeName: themeName,
      lightTheme: FlowyColorScheme.builtIn(themeName, Brightness.light),
      darkTheme: FlowyColorScheme.builtIn(themeName, Brightness.dark),
    );
  }
}
