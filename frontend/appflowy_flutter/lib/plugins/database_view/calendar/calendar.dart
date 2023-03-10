import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/left_bar_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';

import '../../util.dart';
import 'presentation/calendar_page.dart';

class CalendarPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is ViewPB) {
      return CalendarPlugin(pluginType: pluginType, view: data);
    } else {
      throw FlowyPluginException.invalidData;
    }
  }

  @override
  String get menuName => LocaleKeys.calendar_menuName.tr();

  @override
  String get menuIcon => "editor/date";

  @override
  PluginType get pluginType => PluginType.calendar;

  @override
  ViewLayoutTypePB? get layoutType => ViewLayoutTypePB.Calendar;
}

class CalendarPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}

class CalendarPlugin extends Plugin {
  @override
  final ViewPluginNotifier notifier;
  final PluginType _pluginType;

  CalendarPlugin({
    required ViewPB view,
    required PluginType pluginType,
  })  : _pluginType = pluginType,
        notifier = ViewPluginNotifier(view: view);

  @override
  PluginDisplay get display => CalendarPluginDisplay(notifier: notifier);

  @override
  PluginId get id => notifier.view.id;

  @override
  PluginType get ty => _pluginType;
}

class CalendarPluginDisplay extends PluginDisplay {
  final ViewPluginNotifier notifier;
  CalendarPluginDisplay({required this.notifier, Key? key});

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

    return CalendarPage(key: ValueKey(view.id), view: view);
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}
