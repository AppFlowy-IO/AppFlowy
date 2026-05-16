import 'dart:async';
import 'dart:io';

import 'package:flowy_infra/file_picker/file_picker_impl.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'location_service.dart';
import 'models/flowy_dynamic_plugin.dart';

/// A service to maintain the state of the plugins for AppFlowy.
class FlowyPluginService {
  FlowyPluginService._();
  static final FlowyPluginService _instance = FlowyPluginService._();
  static FlowyPluginService get instance => _instance;

  PluginLocationService _locationService = PluginLocationService(
    fallback: getApplicationDocumentsDirectory(),
  );

  void setLocation(PluginLocationService locationService) =>
      _locationService = locationService;

  Future<Iterable<Directory>> get _targets async {
    final location = await _locationService.location;
    final targets = location.listSync().where(FlowyDynamicPlugin.isPlugin);
    return targets.map<Directory>((entity) => entity as Directory).toList();
  }

  /// Searches the [PluginLocationService.location] for plugins and compiles them.
  Future<DynamicPluginLibrary> get plugins async {
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

  /// Searches the plugin registry for a plugin with the given name.
  Future<FlowyDynamicPlugin?> lookup({required String name}) async {
    final library = await plugins;
    return library
        // cast to nullable type to allow return of null if not found.
        .cast<FlowyDynamicPlugin?>()
        // null assert is fine here because the original list was non-nullable
        .firstWhere((plugin) => plugin!.name == name, orElse: () => null);
  }

  /// Adds a plugin to the registry. To construct a [FlowyDynamicPlugin]
  /// use [FlowyDynamicPlugin.encode()]
  Future<void> addPlugin(FlowyDynamicPlugin plugin) async {
    // try to compile the plugin before we add it to the registry.
    final source = await plugin.encode();
    // add the plugin to the registry
    final destionation = [
      (await _locationService.location).path,
      p.basename(source.path),
    ].join(Platform.pathSeparator);

    _copyDirectorySync(source, Directory(destionation));
  }

  /// Removes a plugin from the registry.
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
