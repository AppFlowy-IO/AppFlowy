export "./src/sizes.dart";
export "./src/trash_cell.dart";
export "./src/trash_header.dart";

import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

import 'trash_page.dart';

class TrashPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    return TrashPlugin(pluginType: pluginType);
  }

  @override
  String get menuName => "TrashPB";

  @override
  String get menuIcon => "editor/delete";

  @override
  PluginType get pluginType => PluginType.trash;
}

class TrashPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}

class TrashPlugin extends Plugin {
  final PluginType _pluginType;

  TrashPlugin({required PluginType pluginType}) : _pluginType = pluginType;

  @override
  PluginWidgetBuilder get widgetBuilder => TrashPluginDisplay();

  @override
  PluginId get id => "TrashStack";

  @override
  PluginType get pluginType => _pluginType;
}

class TrashPluginDisplay extends PluginWidgetBuilder {
  @override
  Widget get leftBarItem => FlowyText.medium(LocaleKeys.trash_text.tr());

  @override
  Widget? get rightBarItem => null;

  @override
  Widget buildWidget(PluginContext context) => const TrashPage(
        key: ValueKey('TrashPage'),
      );

  @override
  List<NavigationItem> get navigationItems => [this];
}
