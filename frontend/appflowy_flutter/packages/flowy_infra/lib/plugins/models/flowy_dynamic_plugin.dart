import 'dart:convert';
import 'dart:io';

import 'package:flowy_infra/colorscheme/colorscheme.dart';
import 'package:flowy_infra/theme.dart';
import 'package:path/path.dart' as p;

typedef DynamicPluginLibrary = Iterable<FlowyDynamicPlugin>;

/// A class that encapsulates dynamically loaded plugins for AppFlowy.
///
/// This class can be modified to support loading node widget builders and other
/// plugins that are dynamically loaded at runtime for the editor. For now,
/// it only supports loading app themes.
class FlowyDynamicPlugin {
  /// The plugins should be loaded into a folder with the extension `.flowy_plugin`.
  static bool isPlugin(FileSystemEntity entity) =>
      entity is Directory && p.extension(entity.path).contains('flowy_plugin');
  static Iterable<String> allowedExtensions = [
    'flowy_plugin',
  ];

  String get name => _name;
  late final String _name;

  final String path;

  final Iterable<AppTheme> themes;

  FlowyDynamicPlugin._({
    required this.path,
    required String name,
    this.themes = const [],
  }) : _name = name;

  /// Loads and "compiles" loaded plugins.
  ///
  /// If the plugin loaded does not contain the `.flowy_plugin` extension, this
  /// this method will throw an error. Likewise, if the plugin does not follow
  /// the expected format, this method will throw an error.
  static Future<FlowyDynamicPlugin> compile({required Directory src}) async {
    // throw an error if the plugin does not follow the proper format.
    if (!isPlugin(src)) {
      throw ArgumentError(
          'The plugin source directory must have the extension `.flowy_plugin`.');
    }

    // throws an error if the plugin does not follow the proper format.
    final type = _PluginType.derive(src: src);

    switch (type) {
      case _PluginType.theme:
        return _theme(src: src);
    }
  }

  /// Calls compile and returns null if an error is thrown.
  static Future<FlowyDynamicPlugin?> tryCompile(
      {required Directory src}) async {
    try {
      return await compile(src: src);
    } catch (e) {
      return null;
    }
  }

  /// Theme plugins should have the following format.
  /// > directory.flowy_plugin // plugin root
  /// >   - theme.light.json   // the light theme
  /// >   - theme.dark.json    // the dark theme
  ///
  /// If the theme does not adhere to that format, it is considered an error.
  static Future<FlowyDynamicPlugin> _theme({required Directory src}) async {
    late final String name;
    try {
      name = p.basenameWithoutExtension(src.path).split('.').first;
    } catch (e) {
      throw ArgumentError(
          'The theme plugin does not adhere to the following format: `<plugin_name>.flowy_plugin`.');
    }

    final light = src
        .listSync()
        .where((event) =>
            event is File && p.basename(event.path).contains(_lightExtension))
        .first as File;

    final dark = src
        .listSync()
        .where((event) =>
            event is File && p.basename(event.path).contains(_darkExtension))
        .first as File;

    final theme = AppTheme(
      builtIn: false,
      themeName: name,
      lightTheme:
          FlowyColorScheme.fromJson(jsonDecode(await light.readAsString())),
      darkTheme:
          FlowyColorScheme.fromJson(jsonDecode(await dark.readAsString())),
    );

    return FlowyDynamicPlugin._(
      name: name,
      path: src.path,
      themes: [
        theme,
      ],
    );
  }

  static const String _lightExtension = 'light.json';
  static const String _darkExtension = 'dark.json';
}

enum _PluginType {
  theme._();

  const _PluginType._();

  factory _PluginType.derive({required Directory src}) {
    if (isTheme(src)) {
      return _PluginType.theme;
    }
    throw ArgumentError.value(src, 'src',
        'The plugin type could not be derived from the source directory.');
  }

  static bool isTheme(Directory plugin) {
    final files = plugin.listSync();
    return files.any((entity) =>
            entity is File &&
            p
                .basename(entity.path)
                .endsWith(FlowyDynamicPlugin._lightExtension)) &&
        files.any((entity) =>
            entity is File &&
            p
                .basename(entity.path)
                .endsWith(FlowyDynamicPlugin._darkExtension));
  }
}
