import 'dart:collection';

import 'package:flutter/services.dart';

import '../plugin.dart';
import 'runner.dart';

class PluginSandbox {
  final LinkedHashMap<String, PluginBuilder> _pluginMap = LinkedHashMap();
  late PluginRunner pluginRunner;

  PluginSandbox() {
    pluginRunner = PluginRunner();
  }

  int indexOf(String pluginType) {
    final index = _pluginMap.keys.toList().indexWhere((ty) => ty == pluginType);
    if (index == -1) {
      throw PlatformException(code: '-1', message: "Can't find the flowy plugin type: $pluginType");
    }
    return index;
  }

  Plugin buildPlugin(String pluginType, dynamic data) {
    final index = indexOf(pluginType);
    final plugin = _pluginMap[index]!.build(data);
    return plugin;
  }

  void registerPlugin(String pluginType, PluginBuilder builder) {
    if (_pluginMap.containsKey(pluginType)) {
      throw PlatformException(code: '-1', message: "$pluginType was registered before");
    }
    _pluginMap[pluginType] = builder;
  }

  List<String> get supportPluginTypes => _pluginMap.keys.toList();

  List<PluginBuilder> get builders => _pluginMap.values.toList();
}
