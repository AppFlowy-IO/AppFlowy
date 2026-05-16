import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';

extension AFRolePBExtension on AFRolePB {
  bool get isOwner => this == AFRolePB.Owner;

  bool get isMember => this == AFRolePB.Member;

  bool get canInvite => isOwner;

  bool get canDelete => isOwner;

  bool get canUpdate => isOwner;

  bool get canLeave => this != AFRolePB.Owner;

  String get description {
    switch (this) {
      case AFRolePB.Owner:
        return LocaleKeys.settings_appearance_members_owner.tr();
      case AFRolePB.Member:
        return LocaleKeys.settings_appearance_members_member.tr();
      case AFRolePB.Guest:
        return LocaleKeys.settings_appearance_members_guest.tr();
    }
    throw UnimplementedError('Unknown role: $this');
  }
}
