import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/util.dart';
import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/left_bar_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';

import 'presentation/grid_page.dart';

class GridPluginBuilder implements PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is ViewPB) {
      return GridPlugin(pluginType: pluginType, view: data);
    } else {
      throw FlowyPluginException.invalidData;
    }
  }

  @override
  String get menuName => LocaleKeys.grid_menuName.tr();

  @override
  String get menuIcon => "editor/grid";

  @override
  PluginType get pluginType => PluginType.grid;

  @override
  ViewDataFormatPB get dataFormatType => ViewDataFormatPB.DatabaseFormat;

  @override
  ViewLayoutTypePB? get layoutType => ViewLayoutTypePB.Grid;
}

class GridPluginConfig implements PluginConfig {
  @override
  bool get creatable => true;
}

class GridPlugin extends Plugin {
  @override
  final ViewPluginNotifier notifier;
  final PluginType _pluginType;

  GridPlugin({
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
  ViewPB get view => notifier.view;

  GridPluginDisplay({required this.notifier, Key? key});

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

    return GridPage(key: ValueKey(view.id), view: view);
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}
