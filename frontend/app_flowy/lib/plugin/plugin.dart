library flowy_plugin;

import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flutter/widgets.dart';

export "./src/sandbox.dart";

typedef PluginType = String;

typedef PluginDataType = ViewDataType;

abstract class Plugin {
  PluginType get pluginType;

  String get pluginId;

  bool get enable;

  void dispose();

  PluginDisplay get display;
}

abstract class PluginBuilder {
  Plugin build(dynamic data);

  String get pluginName;

  PluginType get pluginType;

  ViewDataType get dataType;
}

abstract class PluginDisplay with NavigationItem {
  @override
  Widget get leftBarItem;

  @override
  Widget? get rightBarItem;

  List<NavigationItem> get navigationItems;

  Widget buildWidget();
}

void registerPlugin({required PluginBuilder builder}) {
  getIt<PluginSandbox>().registerPlugin(builder.pluginType, builder);
}

Plugin makePlugin({required String pluginType, dynamic data}) {
  final plugin = getIt<PluginSandbox>().buildPlugin(pluginType, data);
  return plugin;
}

enum FlowyPluginException {
  invalidData,
}
