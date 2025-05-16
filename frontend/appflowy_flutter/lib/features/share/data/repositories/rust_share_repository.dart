import 'package:appflowy/features/share/data/models/models.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'share_repository.dart';

class RustShareRepository extends ShareRepository {
  RustShareRepository();

  @override
  Future<FlowyResult<List<SharedUser>, FlowyError>> getSharedUsersInPage({
    required String pageId,
  }) async {
    final request = GetSharedUsersPayloadPB(
      viewId: pageId,
    );
    final result = await FolderEventGetSharedUsers(request).send();

    return result.fold(
      (success) {
        Log.info('get shared users: $success');

        return FlowySuccess(success.sharedUsers);
      },
      (failure) {
        Log.error('getUsersInSharedPage: $failure');

        return FlowyFailure(failure);
      },
    );
  }

  @override
  Future<FlowyResult<void, FlowyError>> removeSharedUserFromPage({
    required String pageId,
    required List<String> emails,
  }) async {
    final request = RemoveUserFromSharedPagePayloadPB(
      viewId: pageId,
      emails: emails,
    );
    final result = await FolderEventRemoveUserFromSharedPage(request).send();

    return result.fold(
      (success) {
        Log.info('remove users($emails) from shared page($pageId)');

        return FlowySuccess(success);
      },
      (failure) {
        Log.error('removeUserFromPage: $failure');

        return FlowyFailure(failure);
      },
    );
  }

  @override
  Future<FlowyResult<void, FlowyError>> sharePageWithUser({
    required String pageId,
    required ShareAccessLevel role,
    required List<String> emails,
  }) async {
    final request = SharePageWithUserPayloadPB(
      viewId: pageId,
      emails: emails,
      accessLevel: role.accessLevel,
    );
    final result = await FolderEventSharePageWithUser(request).send();

    return result.fold(
      (success) {
        Log.info('share page($pageId) with users($emails) with role($role)');

        return FlowySuccess(success);
      },
      (failure) {
        Log.error('sharePageWithUser: $failure');

        return FlowyFailure(failure);
      },
    );
  }

  @override
  Future<FlowyResult<List<SharedUser>, FlowyError>> getAvailableSharedUsers({
    required String pageId,
  }) async {
    // TODO: Implement this
    return FlowySuccess([]);
  }
}

extension on RepeatedSharedUserPB {
  List<SharedUser> get sharedUsers {
    return items.map((e) => e.sharedUser).toList();
  }
}

extension on SharedUserPB {
  SharedUser get sharedUser {
    return SharedUser(
      email: email,
      name: name,
      accessLevel: accessLevel.shareRole,
      role: role.shareRole,
      avatarUrl: avatarUrl,
    );
  }
}

extension on AFAccessLevelPB {
  ShareAccessLevel get shareRole {
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

extension on ShareAccessLevel {
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

extension on AFRolePB {
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

// extension on ShareRole {
//   AFRolePB get role {
//     switch (this) {
//       case ShareRole.guest:
//         return AFRolePB.Guest;
//       case ShareRole.member:
//         return AFRolePB.Member;
//       case ShareRole.owner:
//         return AFRolePB.Owner;
//     }
//   }
// }
