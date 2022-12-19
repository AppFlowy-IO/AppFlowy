import 'package:flowy_infra/colorscheme/colorscheme.dart';
import 'package:flutter/material.dart';

const List<String> builtInThemes = [
  'light',
];

class AppTheme {
  // metadata member
  final FlowyColorScheme lightTheme;
  final FlowyColorScheme darkTheme;
  // static final Map<String, dynamic> _cachedJsonData = {};

  const AppTheme({
    required this.lightTheme,
    required this.darkTheme,
  });

  factory AppTheme.fromName({required String themeName}) {
    // if (builtInThemes.contains(themeName)) {
    //   return AppTheme(
    //     lightTheme: FlowyColorScheme.builtIn(themeName, Brightness.light),
    //     darkTheme: FlowyColorScheme.builtIn(themeName, Brightness.dark),
    //   );
    // } else {
    //   // load from Json
    //   return AppTheme(
    //     lightTheme: FlowyColorScheme.fromJson(_jsonData, Brightness.light),
    //     darkTheme: FlowyColorScheme.fromJson(_jsonData, Brightness.dark),
    //   );
    // }
    return AppTheme(
      lightTheme: FlowyColorScheme.builtIn(themeName, Brightness.light),
      darkTheme: FlowyColorScheme.builtIn(themeName, Brightness.dark),
    );
  }
}
