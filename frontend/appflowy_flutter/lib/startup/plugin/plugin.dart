library flowy_plugin;

import 'package:flutter/widgets.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

export "./src/sandbox.dart";

enum PluginType {
  editor,
  blank,
  trash,
  grid,
  board,
  calendar,
}

typedef PluginId = String;

abstract class Plugin<T> {
  PluginId get id;

  PluginWidgetBuilder get widgetBuilder;

  PluginNotifier? get notifier => null;

  PluginType get pluginType;

  void init() {}

  void dispose() {
    notifier?.dispose();
  }
}

abstract class PluginNotifier<T> {
  /// Notify if the plugin get deleted
  ValueNotifier<T> get isDeleted;

  void dispose() {}
}

abstract class PluginBuilder {
  Plugin build(dynamic data);

  String get menuName;

  FlowySvgData get icon;

  /// The type of this [Plugin]. Each [Plugin] should have a unique [PluginType]
  PluginType get pluginType;

  /// The layoutType is used in the backend to determine the layout of the view.
  /// Currently, AppFlowy supports 4 layout types: Document, Grid, Board, Calendar.
  ViewLayoutPB? get layoutType => ViewLayoutPB.Document;
}

abstract class PluginConfig {
  // Return false will disable the user to create it. For example, a trash plugin shouldn't be created by the user,
  bool get creatable => true;
}

abstract class PluginWidgetBuilder with NavigationItem {
  List<NavigationItem> get navigationItems;

  EdgeInsets get contentPadding =>
      const EdgeInsets.symmetric(horizontal: 40, vertical: 28);

  Widget buildWidget({PluginContext? context, required bool shrinkWrap});
}

class PluginContext {
  PluginContext({required this.onDeleted});

  // calls when widget of the plugin get deleted
  final Function(ViewPB, int?) onDeleted;
}

void registerPlugin({required PluginBuilder builder, PluginConfig? config}) {
  getIt<PluginSandbox>()
      .registerPlugin(builder.pluginType, builder, config: config);
}

/// Make the correct plugin from the [pluginType] and [data]. If the plugin
///  is not registered, it will return a blank plugin.
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
