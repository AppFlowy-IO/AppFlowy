import 'dart:collection';

import 'package:flutter/services.dart';

import '../plugin.dart';
import 'runner.dart';

class PluginSandbox {
  final LinkedHashMap<PluginType, PluginBuilder> _pluginBuilders =
      LinkedHashMap();
  final Map<PluginType, PluginConfig> _pluginConfigs =
      <PluginType, PluginConfig>{};
  late PluginRunner pluginRunner;

  PluginSandbox() {
    pluginRunner = PluginRunner();
  }

  int indexOf(final PluginType pluginType) {
    final index =
        _pluginBuilders.keys.toList().indexWhere((final ty) => ty == pluginType);
    if (index == -1) {
      throw PlatformException(
        code: '-1',
        message: "Can't find the flowy plugin type: $pluginType",
      );
    }
    return index;
  }

  Plugin buildPlugin(final PluginType pluginType, final dynamic data) {
    final plugin = _pluginBuilders[pluginType]!.build(data);
    return plugin;
  }

  void registerPlugin(
    final PluginType pluginType,
    final PluginBuilder builder, {
    final PluginConfig? config,
  }) {
    if (_pluginBuilders.containsKey(pluginType)) {
      throw PlatformException(
        code: '-1',
        message: "$pluginType was registered before",
      );
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
