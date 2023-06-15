import 'dart:async';
import 'dart:io';

import 'package:flowy_infra/file_picker/file_picker_impl.dart';

import 'package:path/path.dart' as p;
import 'location_service.dart';
import 'models/flowy_dynamic_plugin.dart';

/// Singleton class which can only be constructed asynchronously
///
/// The path of the plugins should be initialized by another service
/// since the plugins must be locatable at runtime.
class FlowyPluginService {
  FlowyPluginService._();

  static Future<Iterable<Directory>> get _targets async {
    final location = await PluginLocationService.location;
    final targets = location.listSync().where(FlowyDynamicPlugin.isPlugin);
    return targets.map<Directory>((entity) => entity as Directory).toList();
  }

  static Future<DynamicPluginLibrary> get plugins async {
    final List<FlowyDynamicPlugin> compiled = [];
    for (final src in await _targets) {
      final plugin = await FlowyDynamicPlugin.decode(src: src);
      compiled.add(plugin);
    }
    return compiled;
  }

  /// Chooses a plugin from the file system using FilePickerService and tries to compile it.
  ///
  /// If the operation is cancelled or the plugin is invalid, this method will return null.
  static Future<FlowyDynamicPlugin?> pick({FilePicker? service}) async {
    service ??= FilePicker();

    final result = await service.getDirectoryPath();

    if (result == null) {
      return null;
    }

    final directory = Directory(result);
    return FlowyDynamicPlugin.decode(src: directory);
  }

  static Future<FlowyDynamicPlugin?> lookup({required String name}) async {
    final library = await plugins;
    return library
        // cast to nullable type to allow return of null if not found.
        .cast<FlowyDynamicPlugin?>()
        // null assert is fine here because the original list was non-nullable
        .firstWhere((plugin) => plugin!.name == name, orElse: () => null);
  }

  /// Adds a plugin to the registry.
  static Future<void> addPlugin(FlowyDynamicPlugin plugin) async {
    // try to compile the plugin before we add it to the registry.
    final source = await plugin.encode();
    // add the plugin to the registry
    final destionation = [
      (await PluginLocationService.location).path,
      p.basename(source.path),
    ].join(Platform.pathSeparator);

    _copyDirectorySync(source, Directory(destionation));
  }

  static Future<void> removePlugin(FlowyDynamicPlugin plugin) async {
    final target = plugin.source;
    await target.delete(recursive: true);
  }

  static void _copyDirectorySync(Directory source, Directory destination) {
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }

    for (final child in source.listSync(recursive: false)) {
      final newPath = p.join(destination.path, p.basename(child.path));
      if (child is File) {
        File(newPath)
          ..createSync(recursive: true)
          ..writeAsStringSync(child.readAsStringSync());
      } else if (child is Directory) {
        _copyDirectorySync(child, Directory(newPath));
      }
    }
  }
}
