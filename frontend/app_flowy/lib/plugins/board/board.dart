import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/left_bar_item.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:flutter/material.dart';

import 'presentation/board_page.dart';

class BoardPluginBuilder implements PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is ViewPB) {
      return BoardPlugin(pluginType: pluginType, view: data);
    } else {
      throw FlowyPluginException.invalidData;
    }
  }

  @override
  String get menuName => "Board";

  @override
  PluginType get pluginType => PluginType.board;

  @override
  ViewDataTypePB get dataType => ViewDataTypePB.Database;

  @override
  ViewLayoutTypePB? get subDataType => ViewLayoutTypePB.Board;
}

class BoardPluginConfig implements PluginConfig {
  @override
  bool get creatable => true;
}

class BoardPlugin extends Plugin {
  final ViewPB _view;
  final PluginType _pluginType;

  BoardPlugin({
    required ViewPB view,
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
  final ViewPB _view;
  GridPluginDisplay({required ViewPB view, Key? key}) : _view = view;

  @override
  Widget get leftBarItem => ViewLeftBarItem(view: _view);

  @override
  Widget buildWidget() => BoardPage(view: _view);

  @override
  List<NavigationItem> get navigationItems => [this];
}
