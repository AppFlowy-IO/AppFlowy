import 'dart:async';
import 'dart:io';

import 'location_service.dart';
import 'package:path/path.dart' as p;

import 'flowy_dynamic_plugin.dart';

/// Singleton class which can only be constructed asynchronously
///
/// The path of the plugins should be initialized by another service
/// since the plugins must be locatable at runtime.
class FlowyPluginService {
  FlowyPluginService._();

  static final Completer _completer = Completer();

  static FlowyPluginService? _instance;

  /// A factory constructor that returns the singleton instance of this class
  static Future<FlowyPluginService> get instance async {
    if (_instance == null) {
      _instance = FlowyPluginService._();
      // don't register callback on the file system until
      // the service is initialized.
      final location = await PluginLocationService.location;
      // evaluate plugins here
      await _instance!._compile();
      location.watch().listen(_listen);
      _completer.complete();
    } else if (!_completer.isCompleted) {
      await _completer.future;
    }
    return _instance!;
  }

  static Future<void> _listen(FileSystemEvent event) async {
    // TODO(a-wallen): Invalidate plugins that are removed.
    // TODO(a-wallen): Only compile new plugins that were just added.
    await _instance!._compile();
  }

  Future<Iterable<Directory>> get _srcs async =>
      (await PluginLocationService.location)
          .listSync()
          .where(FlowyDynamicPlugin.isPlugin)
          .map<Directory>((entity) => entity as Directory)
          .toList();

  Future<void> _compile() async {
    final compiled = [];
    for (final src in await _srcs) {
      final plugin = await FlowyDynamicPlugin.compile(src: src);
      compiled.add(plugin);
    }
    _plugins = List.from(compiled);
  }

  late List<FlowyDynamicPlugin> _plugins;

  /// When an awaited instance of [FlowyPluginService] is available, the plugins should
  /// also be initialized, and we can get a list of all libraries that are dynamically
  /// added to the applciation
  ///
  /// This is a copy of the backing property, the plugins should not be modifiable by the user.
  Iterable<FlowyDynamicPlugin> get plugins => List.from(_plugins);
}
