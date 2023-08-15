import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';

extension DatabaseLayoutExtension on DatabaseLayoutPB {
  String layoutName() {
    switch (this) {
      case DatabaseLayoutPB.Board:
        return LocaleKeys.board_menuName.tr();
      case DatabaseLayoutPB.Calendar:
        return LocaleKeys.calendar_menuName.tr();
      case DatabaseLayoutPB.Grid:
        return LocaleKeys.grid_menuName.tr();
      default:
        return "";
    }
  }

  FlowySvgData get icon {
    switch (this) {
      case DatabaseLayoutPB.Board:
        return FlowySvgs.board_s;
      case DatabaseLayoutPB.Calendar:
      case DatabaseLayoutPB.Grid:
        return FlowySvgs.grid_s;
    }
    throw UnimplementedError();
  }
}
