import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

/// The access level a user can have on a shared page.
enum ShareAccessLevel {
  /// Can view the page only.
  readOnly,

  /// Can read and comment on the page.
  readAndComment,

  /// Can read and write to the page.
  readAndWrite,

  /// Full access (edit, share, remove, etc.) and can add new users.
  fullAccess;

  String get title {
    switch (this) {
      case ShareAccessLevel.readOnly:
        return LocaleKeys.shareTab_accessLevel_view.tr();
      case ShareAccessLevel.readAndComment:
        return LocaleKeys.shareTab_accessLevel_comment.tr();
      case ShareAccessLevel.readAndWrite:
        return LocaleKeys.shareTab_accessLevel_edit.tr();
      case ShareAccessLevel.fullAccess:
        return LocaleKeys.shareTab_accessLevel_fullAccess.tr();
    }
  }

  String get subtitle {
    switch (this) {
      case ShareAccessLevel.readOnly:
        return LocaleKeys.shareTab_cantMakeChanges.tr();
      case ShareAccessLevel.readAndComment:
        return LocaleKeys.shareTab_canMakeAnyChanges.tr();
      case ShareAccessLevel.readAndWrite:
        return LocaleKeys.shareTab_canMakeAnyChanges.tr();
      case ShareAccessLevel.fullAccess:
        return LocaleKeys.shareTab_canMakeAnyChanges.tr();
    }
  }

  FlowySvgData get icon {
    switch (this) {
      case ShareAccessLevel.readOnly:
        return FlowySvgs.access_level_view_m;
      case ShareAccessLevel.readAndComment:
        return FlowySvgs.access_level_edit_m;
      case ShareAccessLevel.readAndWrite:
        return FlowySvgs.access_level_edit_m;
      case ShareAccessLevel.fullAccess:
        return FlowySvgs.access_level_edit_m;
    }
  }
}
