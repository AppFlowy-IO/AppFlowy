import 'package:flowy_infra/colorscheme/colorscheme.dart';
import 'plugins/service/plugin_service.dart';

class BuiltInTheme {
  static const String defaultTheme = 'Default';
  static const String dandelion = 'Dandelion';
  static const String lavender = 'Lavender';
}

class AppTheme {
  // metadata member
  final bool builtIn;
  final String themeName;
  final FlowyColorScheme lightTheme;
  final FlowyColorScheme darkTheme;
  // static final Map<String, dynamic> _cachedJsonData = {};

  const AppTheme({
    required this.builtIn,
    required this.themeName,
    required this.lightTheme,
    required this.darkTheme,
  });

  static Future<Iterable<AppTheme>> get _plugins async {
    final instance = await FlowyPluginService.instance;
    final plugins = await instance.plugins;
    return plugins.map((plugin) => plugin.themes).expand((element) => element);
  }

  static Iterable<AppTheme> get builtins => themeMap.entries
      .map(
        (entry) => AppTheme(
          builtIn: true,
          themeName: entry.key,
          lightTheme: entry.value[0],
          darkTheme: entry.value[1],
        ),
      )
      .toList();

  static Future<Iterable<AppTheme>> get themes async => [
        ...builtins,
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
