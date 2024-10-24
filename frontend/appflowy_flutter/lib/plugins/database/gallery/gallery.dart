import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';

class GalleryPluginBuilder implements PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is ViewPB) {
      return DatabaseTabBarViewPlugin(pluginType: pluginType, view: data);
    } else {
      throw FlowyPluginException.invalidData;
    }
  }

  @override
  String get menuName => LocaleKeys.databaseGallery_menuName.tr();

  @override
  FlowySvgData get icon => FlowySvgs.gallery_s;

  @override
  PluginType get pluginType => PluginType.gallery;

  @override
  ViewLayoutPB get layoutType => ViewLayoutPB.Gallery;
}

class GalleryPluginConfig implements PluginConfig {
  @override
  bool get creatable => true;
}
