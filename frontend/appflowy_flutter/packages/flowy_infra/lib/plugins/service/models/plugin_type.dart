import 'dart:io';

import 'package:flowy_infra/plugins/service/models/flowy_dynamic_plugin.dart';
import 'package:path/path.dart' as p;

enum PluginType {
  theme._();

  const PluginType._();

  factory PluginType.from({required Directory src}) {
    if (_isTheme(src)) {
      return PluginType.theme;
    }
    throw ArgumentError.value(src, 'src',
        'The plugin type could not be derived from the source directory.');
  }

  static bool _isTheme(Directory plugin) {
    final files = plugin.listSync();
    return files.any((entity) =>
            entity is File &&
            p
                .basename(entity.path)
                .endsWith(FlowyDynamicPlugin.lightExtension)) &&
        files.any((entity) =>
            entity is File &&
            p.basename(entity.path).endsWith(FlowyDynamicPlugin.darkExtension));
  }
}
