import 'package:appflowy/features/share/data/models/share_role.dart';
import 'package:appflowy/features/share/data/models/shared_user.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'share_repository.dart';

class RustShareRepository extends ShareRepository {
  RustShareRepository();

  @override
  Future<FlowyResult<List<SharedUser>, FlowyError>> getUsersInSharedPage({
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
  Future<FlowyResult<void, FlowyError>> removeUserFromPage({
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
    required ShareRole role,
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
      role: accessLevel.shareRole,
      avatarUrl: avatarUrl,
    );
  }
}

extension on AFAccessLevelPB {
  ShareRole get shareRole {
    switch (this) {
      case AFAccessLevelPB.ReadOnly:
        return ShareRole.readOnly;
      case AFAccessLevelPB.ReadAndComment:
        return ShareRole.readAndComment;
      case AFAccessLevelPB.ReadAndWrite:
        return ShareRole.readAndWrite;
      case AFAccessLevelPB.FullAccess:
        return ShareRole.fullAccess;
      default:
        throw Exception('Unknown share role: $this');
    }
  }
}

extension on ShareRole {
  AFAccessLevelPB get accessLevel {
    switch (this) {
      case ShareRole.readOnly:
        return AFAccessLevelPB.ReadOnly;
      case ShareRole.readAndComment:
        return AFAccessLevelPB.ReadAndComment;
      case ShareRole.readAndWrite:
        return AFAccessLevelPB.ReadAndWrite;
      case ShareRole.fullAccess:
        return AFAccessLevelPB.FullAccess;
    }
  }
}
