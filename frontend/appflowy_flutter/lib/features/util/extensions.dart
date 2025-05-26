import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/shared_section/models/shared_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart' as folder;
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart'
    as user;

extension RepeatedSharedViewResponsePBExtension
    on RepeatedSharedViewResponsePB {
  SharedPages get sharedPages {
    return sharedViews.map((e) => e.sharedPage).toList();
  }
}

extension SharedViewPBExtension on SharedViewPB {
  SharedPage get sharedPage {
    return SharedPage(
      view: view,
      accessLevel: accessLevel.shareAccessLevel,
    );
  }
}

extension RepeatedSharedUserPBExtension on RepeatedSharedUserPB {
  SharedUsers get sharedUsers {
    return items.map((e) => e.sharedUser).toList();
  }
}

extension SharedUserPBExtension on SharedUserPB {
  SharedUser get sharedUser {
    return SharedUser(
      email: email,
      name: name,
      accessLevel: accessLevel.shareAccessLevel,
      role: role.shareRole,
      avatarUrl: avatarUrl,
    );
  }
}

extension AFAccessLevelPBExtension on AFAccessLevelPB {
  ShareAccessLevel get shareAccessLevel {
    switch (this) {
      case AFAccessLevelPB.ReadOnly:
        return ShareAccessLevel.readOnly;
      case AFAccessLevelPB.ReadAndComment:
        return ShareAccessLevel.readAndComment;
      case AFAccessLevelPB.ReadAndWrite:
        return ShareAccessLevel.readAndWrite;
      case AFAccessLevelPB.FullAccess:
        return ShareAccessLevel.fullAccess;
      default:
        throw Exception('Unknown share role: $this');
    }
  }
}

extension ShareAccessLevelExtension on ShareAccessLevel {
  AFAccessLevelPB get accessLevel {
    switch (this) {
      case ShareAccessLevel.readOnly:
        return AFAccessLevelPB.ReadOnly;
      case ShareAccessLevel.readAndComment:
        return AFAccessLevelPB.ReadAndComment;
      case ShareAccessLevel.readAndWrite:
        return AFAccessLevelPB.ReadAndWrite;
      case ShareAccessLevel.fullAccess:
        return AFAccessLevelPB.FullAccess;
    }
  }
}

extension AFRolePBExtension on AFRolePB {
  ShareRole get shareRole {
    switch (this) {
      case AFRolePB.Guest:
        return ShareRole.guest;
      case AFRolePB.Member:
        return ShareRole.member;
      case AFRolePB.Owner:
        return ShareRole.owner;
      default:
        throw Exception('Unknown share role: $this');
    }
  }
}

extension ShareRoleExtension on ShareRole {
  user.AFRolePB get userRole {
    switch (this) {
      case ShareRole.guest:
        return user.AFRolePB.Guest;
      case ShareRole.member:
        return user.AFRolePB.Member;
      case ShareRole.owner:
        return user.AFRolePB.Owner;
    }
  }

  folder.AFRolePB get folderRole {
    switch (this) {
      case ShareRole.guest:
        return folder.AFRolePB.Guest;
      case ShareRole.member:
        return folder.AFRolePB.Member;
      case ShareRole.owner:
        return folder.AFRolePB.Owner;
    }
  }
}
