import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/left_bar_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
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
  String get menuName => LocaleKeys.board_menuName.tr();

  @override
  String get menuIcon => "editor/board";

  @override
  PluginType get pluginType => PluginType.board;

  @override
  ViewLayoutPB? get layoutType => ViewLayoutPB.Board;
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
  PluginWidgetBuilder get widgetBuilder =>
      BoardPluginWidgetBuilder(notifier: notifier);

  @override
  PluginId get id => notifier.view.id;

  @override
  PluginType get pluginType => _pluginType;
}

class BoardPluginWidgetBuilder extends PluginWidgetBuilder {
  final ViewPluginNotifier notifier;
  BoardPluginWidgetBuilder({required this.notifier, Key? key});

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
