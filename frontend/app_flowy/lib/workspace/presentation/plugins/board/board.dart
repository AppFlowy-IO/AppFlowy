import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/plugins/widgets/left_bar_item.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:app_flowy/plugin/plugin.dart';
import 'package:flutter/material.dart';

import 'src/board_page.dart';

class BoardPluginBuilder implements PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is View) {
      return BoardPlugin(pluginType: pluginType, view: data);
    } else {
      throw FlowyPluginException.invalidData;
    }
  }

  @override
  String get menuName => "Board";

  @override
  PluginType get pluginType => DefaultPlugin.board.type();

  @override
  ViewDataType get dataType => ViewDataType.Grid;
}

class BoardPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}

class BoardPlugin extends Plugin {
  final View _view;
  final PluginType _pluginType;

  BoardPlugin({
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
  Widget get leftBarItem => ViewLeftBarItem(view: _view);

  @override
  Widget buildWidget() => BoardPage(view: _view);

  @override
  List<NavigationItem> get navigationItems => [this];
}
