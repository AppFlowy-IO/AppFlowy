import 'dart:collection';

import 'package:flutter/services.dart';

import '../plugin.dart';
import 'runner.dart';

class PluginSandbox {
  final LinkedHashMap<PluginType, PluginBuilder> _pluginMap = LinkedHashMap();
  late PluginRunner pluginRunner;

  PluginSandbox() {
    pluginRunner = PluginRunner();
  }

  int indexOf(PluginType pluginType) {
    final index = _pluginMap.keys.toList().indexWhere((ty) => ty == pluginType);
    if (index == -1) {
      throw PlatformException(code: '-1', message: "Can't find the flowy plugin type: $pluginType");
    }
    return index;
  }

  Plugin buildPlugin(PluginType pluginType, dynamic data) {
    final plugin = _pluginMap[pluginType]!.build(data);
    return plugin;
  }

  void registerPlugin(PluginType pluginType, PluginBuilder builder) {
    if (_pluginMap.containsKey(pluginType)) {
      throw PlatformException(code: '-1', message: "$pluginType was registered before");
    }
    _pluginMap[pluginType] = builder;
  }

  List<int> get supportPluginTypes => _pluginMap.keys.toList();

  List<PluginBuilder> get builders => _pluginMap.values.toList();
}
