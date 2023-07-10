import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/tar_bar/tab_bar_view.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';

class CalendarPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is ViewPB) {
      return DatabaseTabBarViewPlugin(pluginType: pluginType, view: data);
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
  ViewLayoutPB? get layoutType => ViewLayoutPB.Calendar;
}

class CalendarPluginConfig implements PluginConfig {
  @override
  bool get creatable => true;
}
