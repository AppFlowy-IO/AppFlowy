import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:app_flowy/plugin/plugin.dart';
import 'package:flutter/material.dart';

import 'src/grid_page.dart';

class GridPluginBuilder implements PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is View) {
      return GridPlugin(pluginType: pluginType, view: data);
    } else {
      throw FlowyPluginException.invalidData;
    }
  }

  @override
  String get menuName => "Grid";

  @override
  PluginType get pluginType => DefaultPlugin.grid.type();

  @override
  ViewDataType get dataType => ViewDataType.Grid;
}

class GridPluginConfig implements PluginConfig {
  @override
  bool get creatable => true;
}

class GridPlugin extends Plugin {
  final View _view;
  final PluginType _pluginType;

  GridPlugin({
    required View view,
    required PluginType pluginType,
  })  : _pluginType = pluginType,
        _view = view;

  @override
  PluginDisplay get display => GridPluginDisplay(view: _view);

  @override
  PluginId get id => _view.id;

  @override
  PluginType get ty => _pluginType;
}

class GridPluginDisplay extends PluginDisplay {
  final View _view;
  GridPluginDisplay({required View view, Key? key}) : _view = view;

  @override
  Widget get leftBarItem => const FlowyText.medium("Grid demo", fontSize: 12);

  @override
  Widget buildWidget() => GridPage(view: _view);

  @override
  List<NavigationItem> get navigationItems => [this];
}
