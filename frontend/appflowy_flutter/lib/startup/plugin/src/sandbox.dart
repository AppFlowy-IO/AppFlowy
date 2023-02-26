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

  int indexOf(PluginType pluginType) {
    final index =
        _pluginBuilders.keys.toList().indexWhere((ty) => ty == pluginType);
    if (index == -1) {
      throw PlatformException(
          code: '-1', message: "Can't find the flowy plugin type: $pluginType");
    }
    return index;
  }

  Plugin buildPlugin(PluginType pluginType, dynamic data) {
    final plugin = _pluginBuilders[pluginType]!.build(data);
    return plugin;
  }

  void registerPlugin(PluginType pluginType, PluginBuilder builder,
      {PluginConfig? config}) {
    if (_pluginBuilders.containsKey(pluginType)) {
      throw PlatformException(
          code: '-1', message: "$pluginType was registered before");
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
