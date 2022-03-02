library flowy_plugin;

import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flutter/widgets.dart';

export "./src/sandbox.dart";

typedef PluginType = int;

typedef PluginDataType = ViewDataType;

typedef PluginId = String;

abstract class Plugin {
  PluginId get pluginId;

  PluginDisplay get pluginDisplay;

  PluginType get pluginType;

  ChangeNotifier? get displayNotifier => null;

  void dispose();
}

abstract class PluginBuilder {
  Plugin build(dynamic data);

  String get menuName;

  PluginType get pluginType;

  ViewDataType get dataType => ViewDataType.PlainText;
}

abstract class PluginConfig {
  bool get creatable => true;
}

abstract class PluginDisplay with NavigationItem {
  @override
  Widget get leftBarItem;

  @override
  Widget? get rightBarItem;

  List<NavigationItem> get navigationItems;

  Widget buildWidget();
}

void registerPlugin({required PluginBuilder builder, PluginConfig? config}) {
  getIt<PluginSandbox>().registerPlugin(builder.pluginType, builder, config: config);
}

Plugin makePlugin({required PluginType pluginType, dynamic data}) {
  final plugin = getIt<PluginSandbox>().buildPlugin(pluginType, data);
  return plugin;
}

List<PluginBuilder> pluginBuilders() {
  final pluginBuilders = getIt<PluginSandbox>().builders;
  final pluginConfigs = getIt<PluginSandbox>().pluginConfigs;
  return pluginBuilders.where(
    (builder) {
      final config = pluginConfigs[builder.pluginType]?.creatable;
      return config ?? true;
    },
  ).toList();
}

enum FlowyPluginException {
  invalidData,
}
