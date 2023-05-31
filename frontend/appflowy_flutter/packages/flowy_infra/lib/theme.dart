import 'package:flowy_infra/colorscheme/colorscheme.dart';
import 'package:flutter/material.dart';

class BuiltInTheme {
  static const String defaultTheme = 'Default';
  static const String dandelion = 'Dandelion';
  static const String lavender = 'Lavender';
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

  static Future<Iterable<AppTheme>> get _plugins async =>
      (await FlowyPluginService.instance)
          .plugins
          .map((plugin) => plugin.themes)
          .expand((element) => element);

  static Iterable<AppTheme> get _builtins => themeMap.entries
      .map(
        (entry) => AppTheme(
          themeName: entry.key,
          lightTheme: entry.value[0],
          darkTheme: entry.value[1],
        ),
      )
      .toList();

  static Future<Iterable<AppTheme>> get themes async => [
        ..._builtins,
        ...(await _plugins),
      ];

  static Future<AppTheme> fromName(String themeName) async {
    for (final theme in await themes) {
      if (theme.themeName == themeName) {
        return theme;
      }
    }
    throw ArgumentError('The theme $themeName does not exist.');
  }
}
