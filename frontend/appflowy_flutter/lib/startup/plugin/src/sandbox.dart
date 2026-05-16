import 'dart:collection';

import 'package:appflowy/plugins/blank/blank.dart';
import 'package:flutter/services.dart';

import '../plugin.dart';
import 'runner.dart';

class PluginSandbox {
  PluginSandbox() {
    pluginRunner = PluginRunner();
  }

  final LinkedHashMap<PluginType, PluginBuilder> _pluginBuilders =
      LinkedHashMap();
  final Map<PluginType, PluginConfig> _pluginConfigs =
      <PluginType, PluginConfig>{};
  late PluginRunner pluginRunner;

  int indexOf(PluginType pluginType) {
    final index =
        _pluginBuilders.keys.toList().indexWhere((ty) => ty == pluginType);
    if (index == -1) {
      throw PlatformException(
        code: '-1',
        message: "Can't find the flowy plugin type: $pluginType",
      );
    }
    return index;
  }

  /// Build a plugin from [data] with [pluginType]
  /// If the [pluginType] is not registered, it will return a blank plugin
  Plugin buildPlugin(PluginType pluginType, dynamic data) {
    final builder = _pluginBuilders[pluginType] ?? BlankPluginBuilder();
    return builder.build(data);
  }

  void registerPlugin(
    PluginType pluginType,
    PluginBuilder builder, {
    PluginConfig? config,
  }) {
    if (_pluginBuilders.containsKey(pluginType)) {
      return;
    }
    _pluginBuilders[pluginType] = builder;

    if (config != null) {
      _pluginConfigs[pluginType] = config;
    }
  }

  List<PluginType> get supportPluginTypes => _pluginBuilders.keys.toList();

  List<PluginBuilder> get builders => _pluginBuilders.values.toList();

  Map<PluginType, PluginConfig> get pluginConfigs => _pluginConfigs;
}
