import 'package:app_flowy/plugins/util.dart';
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
  ViewLayoutTypePB? get layoutType => ViewLayoutTypePB.Board;
}

class BoardPluginConfig implements PluginConfig {
  @override
  bool get creatable => true;
}

class BoardPlugin extends Plugin {
  @override
  final ViewPluginNotifier notifier;
  final PluginType _pluginType;

  BoardPlugin({
    required ViewPB view,
    required PluginType pluginType,
  })  : _pluginType = pluginType,
        notifier = ViewPluginNotifier(view: view);

  @override
  PluginDisplay get display => GridPluginDisplay(notifier: notifier);

  @override
  PluginId get id => notifier.view.id;

  @override
  PluginType get ty => _pluginType;
}

class GridPluginDisplay extends PluginDisplay {
  final ViewPluginNotifier notifier;
  GridPluginDisplay({required this.notifier, Key? key});

  ViewPB get view => notifier.view;

  @override
  Widget get leftBarItem => ViewLeftBarItem(view: view);

  @override
  Widget buildWidget(PluginContext context) {
    notifier.isDeleted.addListener(() {
      notifier.isDeleted.value.fold(() => null, (deletedView) {
        if (deletedView.hasIndex()) {
          context.onDeleted(view, deletedView.index);
        }
      });
    });

    return BoardPage(key: ValueKey(view.id), view: view);
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}
