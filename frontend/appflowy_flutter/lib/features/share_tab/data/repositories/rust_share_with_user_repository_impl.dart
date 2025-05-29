import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/util/extensions.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'share_with_user_repository.dart';

class RustShareWithUserRepositoryImpl extends ShareWithUserRepository {
  RustShareWithUserRepositoryImpl();

  @override
  Future<FlowyResult<SharedUsers, FlowyError>> getSharedUsersInPage({
    required String pageId,
  }) async {
    final request = GetSharedUsersPayloadPB(
      viewId: pageId,
    );
    final result = await FolderEventGetSharedUsers(request).send();

    return result.fold(
      (success) {
        Log.debug('get shared users: $success');

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
    required ShareAccessLevel accessLevel,
    required List<String> emails,
  }) async {
    final request = SharePageWithUserPayloadPB(
      viewId: pageId,
      emails: emails,
      accessLevel: accessLevel.accessLevel,
    );
    final result = await FolderEventSharePageWithUser(request).send();

    return result.fold(
      (success) {
        Log.info(
          'share page($pageId) with users($emails) with access level($accessLevel)',
        );

        return FlowySuccess(success);
      },
      (failure) {
        Log.error('sharePageWithUser: $failure');

        return FlowyFailure(failure);
      },
    );
  }

  @override
  Future<FlowyResult<SharedUsers, FlowyError>> getAvailableSharedUsers({
    required String pageId,
  }) async {
    return FlowySuccess([]);
  }

  @override
  Future<FlowyResult<void, FlowyError>> changeRole({
    required String workspaceId,
    required String email,
    required ShareRole role,
  }) async {
    final request = UpdateWorkspaceMemberPB(
      workspaceId: workspaceId,
      email: email,
      role: role.userRole,
    );
    final result = await UserEventUpdateWorkspaceMember(request).send();
    return result.fold(
      (success) {
        Log.info(
          'change role($role) for user($email) in workspaceId($workspaceId)',
        );
        return FlowySuccess(success);
      },
      (failure) {
        Log.error(
          'failed to change role($role) for user($email) in workspaceId($workspaceId)',
          failure,
        );
        return FlowyFailure(failure);
      },
    );
  }
}
