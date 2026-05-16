import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file/memory.dart';
import 'package:flowy_infra/colorscheme/colorscheme.dart';
import 'package:flowy_infra/plugins/service/models/exceptions.dart';
import 'package:flowy_infra/theme.dart';
import 'package:path/path.dart' as p;

import 'plugin_type.dart';

typedef DynamicPluginLibrary = Iterable<FlowyDynamicPlugin>;

/// A class that encapsulates dynamically loaded plugins for AppFlowy.
///
/// This class can be modified to support loading node widget builders and other
/// plugins that are dynamically loaded at runtime for the editor. For now,
/// it only supports loading app themes.
class FlowyDynamicPlugin {
  FlowyDynamicPlugin._({
    required String name,
    required String path,
    this.theme,
  })  : _name = name,
        _path = path;

  /// The plugins should be loaded into a folder with the extension `.flowy_plugin`.
  static bool isPlugin(FileSystemEntity entity) =>
      entity is Directory && p.extension(entity.path).contains(ext);

  /// The extension for the plugin folder.
  static const String ext = 'flowy_plugin';
  static String get lightExtension => ['light', 'json'].join('.');
  static String get darkExtension => ['dark', 'json'].join('.');

  String get name => _name;
  late final String _name;

  String get _fsPluginName => [name, ext].join('.');

  final AppTheme? theme;
  final String _path;

  Directory get source {
    return Directory(_path);
  }

  /// Loads and "compiles" loaded plugins.
  ///
  /// If the plugin loaded does not contain the `.flowy_plugin` extension, this
  /// this method will throw an error. Likewise, if the plugin does not follow
  /// the expected format, this method will throw an error.
  static Future<FlowyDynamicPlugin> decode({required Directory src}) async {
    // throw an error if the plugin does not follow the proper format.
    if (!isPlugin(src)) {
      throw PluginCompilationException(
        'The plugin directory must have the extension `.flowy_plugin`.',
      );
    }

    // throws an error if the plugin does not follow the proper format.
    final type = PluginType.from(src: src);

    switch (type) {
      case PluginType.theme:
        return _theme(src: src);
    }
  }

  /// Encodes the plugin in memory. The Directory given is not the actual
  /// directory on the file system, but rather a virtual directory in memory.
  ///
  /// Instances of this class should always have a path on disk, otherwise a
  /// compilation error will be thrown during the construction of this object.
  Future<Directory> encode() async {
    final fs = MemoryFileSystem();
    final directory = fs.directory(_fsPluginName)..createSync();

    final lightThemeFileName = '$name.$lightExtension';
    directory.childFile(lightThemeFileName).createSync();
    directory
        .childFile(lightThemeFileName)
        .writeAsStringSync(jsonEncode(theme!.lightTheme.toJson()));

    final darkThemeFileName = '$name.$darkExtension';
    directory.childFile(darkThemeFileName).createSync();
    directory
        .childFile(darkThemeFileName)
        .writeAsStringSync(jsonEncode(theme!.darkTheme.toJson()));

    return directory;
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
      throw PluginCompilationException(
        'The theme plugin does not adhere to the following format: `<plugin_name>.flowy_plugin`.',
      );
    }

    final light = src
        .listSync()
        .where((event) =>
            event is File && p.basename(event.path).contains(lightExtension))
        .first as File;

    final dark = src
        .listSync()
        .where((event) =>
            event is File && p.basename(event.path).contains(darkExtension))
        .first as File;

    late final FlowyColorScheme lightTheme;
    late final FlowyColorScheme darkTheme;

    try {
      lightTheme = FlowyColorScheme.fromJsonSoft(
        await jsonDecode(await light.readAsString()),
      );
    } catch (e) {
      throw PluginCompilationException(
        'The light theme json file is not valid.',
      );
    }

    try {
      darkTheme = FlowyColorScheme.fromJsonSoft(
        await jsonDecode(await dark.readAsString()),
        Brightness.dark,
      );
    } catch (e) {
      throw PluginCompilationException(
        'The dark theme json file is not valid.',
      );
    }

    final theme = AppTheme(
      themeName: name,
      builtIn: false,
      lightTheme: lightTheme,
      darkTheme: darkTheme,
    );

    return FlowyDynamicPlugin._(
      name: theme.themeName,
      path: src.path,
      theme: theme,
    );
  }
}
