import 'package:flowy_infra/colorscheme/colorscheme.dart';
import 'package:flutter/material.dart';

class BuiltInTheme {
  static const String light = 'light';
  static const String dandelion = 'dandelion';
  static const String lavender = 'lavender';
}

class AppTheme {
  // metadata member
  final String themeName;
  final FlowyColorScheme lightTheme;
  final FlowyColorScheme darkTheme;
  // static final Map<String, dynamic> _cachedJsonData = {};

  const AppTheme({
    required this.themeName,
    required this.lightTheme,
    required this.darkTheme,
  });

  factory AppTheme.fromName(String themeName) {
    return AppTheme(
      themeName: themeName,
      lightTheme: FlowyColorScheme.builtIn(themeName, Brightness.light),
      darkTheme: FlowyColorScheme.builtIn(themeName, Brightness.dark),
    );
  }
}
