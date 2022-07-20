library flowy_plugin;

import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/widgets.dart';

export "./src/sandbox.dart";

enum DefaultPlugin {
  quill,
  blank,
  trash,
  grid,
  board,
}

extension FlowyDefaultPluginExt on DefaultPlugin {
  int type() {
    switch (this) {
      case DefaultPlugin.quill:
        return 0;
      case DefaultPlugin.blank:
        return 1;
      case DefaultPlugin.trash:
        return 2;
      case DefaultPlugin.grid:
        return 3;
      case DefaultPlugin.board:
        return 4;
    }
  }
}

typedef PluginType = int;
typedef PluginDataType = ViewDataType;
typedef PluginId = String;

abstract class Plugin {
  PluginId get id;

  PluginDisplay get display;

  PluginType get ty;

  void dispose() {}
}

abstract class PluginBuilder {
  Plugin build(dynamic data);

  String get menuName;

  PluginType get pluginType;

  ViewDataType get dataType => ViewDataType.TextBlock;
}

abstract class PluginConfig {
  // Return false will disable the user to create it. For example, a trash plugin shouldn't be created by the user,
  bool get creatable => true;
}

abstract class PluginDisplay<T> with NavigationItem {
  List<NavigationItem> get navigationItems;

  PublishNotifier<T>? get notifier => null;

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
