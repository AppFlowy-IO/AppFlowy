import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/util/extensions.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';

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
        Log.debug('get shared users success: $success');

        return FlowySuccess(success.sharedUsers);
      },
      (failure) {
        Log.error('get shared users failed: $failure');

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
        Log.debug('remove users($emails) from shared page($pageId)');

        return FlowySuccess(success);
      },
      (failure) {
        Log.error('remove users($emails) from shared page($pageId): $failure');

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
      autoConfirm: true,
    );
    final result = await FolderEventSharePageWithUser(request).send();

    return result.fold(
      (success) {
        Log.debug(
          'share page($pageId) with users($emails) with access level($accessLevel)',
        );

        return FlowySuccess(success);
      },
      (failure) {
        Log.error(
          'share page($pageId) with users($emails) with access level($accessLevel): $failure',
        );

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
        Log.debug(
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

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> getCurrentUserProfile() async {
    final result = await UserEventGetUserProfile().send();
    return result;
  }

  @override
  Future<FlowyResult<SharedSectionType, FlowyError>> getCurrentPageSectionType({
    required String pageId,
  }) async {
    final request = ViewIdPB.create()..value = pageId;
    final result = await FolderEventGetViewAncestors(request).send();
    final ancestors = result.fold(
      (s) => s.items,
      (f) => <ViewPB>[],
    );
    final space = ancestors.firstWhereOrNull((e) => e.isSpace);

    if (space == null) {
      return FlowySuccess(SharedSectionType.unknown);
    }

    final sectionType = switch (space.spacePermission) {
      SpacePermission.publicToAll => SharedSectionType.public,
      SpacePermission.private => SharedSectionType.private,
    };

    return FlowySuccess(sectionType);
  }

  @override
  Future<bool> getUpgradeToProButtonClicked({
    required String workspaceId,
  }) async {
    final result = await getIt<KeyValueStorage>().getWithFormat(
      '${KVKeys.hasClickedUpgradeToProButton}_$workspaceId',
      (value) => bool.parse(value),
    );
    if (result == null) {
      return false;
    }
    return result;
  }

  @override
  Future<void> setUpgradeToProButtonClicked({
    required String workspaceId,
  }) async {
    await getIt<KeyValueStorage>().set(
      '${KVKeys.hasClickedUpgradeToProButton}_$workspaceId',
      'true',
    );
  }
}
