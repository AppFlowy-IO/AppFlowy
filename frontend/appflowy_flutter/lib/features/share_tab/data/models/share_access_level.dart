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

  String get i18n {
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
}
