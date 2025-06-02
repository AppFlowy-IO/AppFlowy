import 'package:appflowy/features/page_access_level/data/repositories/page_access_level_repository.dart';
import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/util/extensions.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';

class RustPageAccessLevelRepositoryImpl implements PageAccessLevelRepository {
  @override
  Future<FlowyResult<ViewPB, FlowyError>> getView(String pageId) async {
    final result = await ViewBackendService.getView(pageId);
    return result.fold(
      (view) {
        Log.info('get view success: ${view.id}');
        return FlowyResult.success(view);
      },
      (error) {
        Log.error('failed to get view, error: $error');
        return FlowyResult.failure(error);
      },
    );
  }

  @override
  Future<FlowyResult<void, FlowyError>> lockView(String pageId) async {
    final result = await ViewBackendService.lockView(pageId);
    return result.fold(
      (_) {
        Log.info('lock view success: $pageId');
        return FlowyResult.success(null);
      },
      (error) {
        Log.error('failed to lock view, error: $error');
        return FlowyResult.failure(error);
      },
    );
  }

  @override
  Future<FlowyResult<void, FlowyError>> unlockView(String pageId) async {
    final result = await ViewBackendService.unlockView(pageId);
    return result.fold(
      (_) {
        Log.info('unlock view success: $pageId');
        return FlowyResult.success(null);
      },
      (error) {
        Log.error('failed to unlock view, error: $error');
        return FlowyResult.failure(error);
      },
    );
  }

  @override
  Future<FlowyResult<ShareAccessLevel, FlowyError>> getAccessLevel(
    String pageId,
  ) async {
    final userResult = await UserBackendService.getCurrentUserProfile();
    final user = userResult.fold(
      (s) => s,
      (_) => null,
    );
    if (user == null) {
      return FlowyResult.failure(
        FlowyError(
          code: ErrorCode.Internal,
          msg: 'User not found',
        ),
      );
    }

    if (user.userAuthType == AuthTypePB.Local) {
      // Local user can always have full access.
      return FlowyResult.success(ShareAccessLevel.fullAccess);
    }

    if (user.workspaceType == WorkspaceTypePB.LocalW) {
      // Local workspace can always have full access.
      return FlowyResult.success(ShareAccessLevel.fullAccess);
    }

    final email = user.email;

    final request = GetSharedUsersPayloadPB(
      viewId: pageId,
    );
    final result = await FolderEventGetSharedUsers(request).send();
    return result.fold(
      (success) {
        final accessLevel = success.items
                .firstWhereOrNull(
                  (item) => item.email == email,
                )
                ?.accessLevel
                .shareAccessLevel ??
            ShareAccessLevel.readAndWrite;

        Log.debug('current user access level: $accessLevel, in page: $pageId');

        return FlowyResult.success(accessLevel);
      },
      (failure) {
        Log.error(
          'failed to get user access level: $failure, in page: $pageId',
        );

        // return the read and write access level if the user is not found
        return FlowyResult.success(ShareAccessLevel.readAndWrite);
      },
    );
  }

  @override
  Future<FlowyResult<SharedSectionType, FlowyError>> getSectionType(
    String pageId,
  ) async {
    final request = ViewIdPB(value: pageId);
    final result = await FolderEventGetSharedViewSection(request).send();
    return result.fold(
      (success) {
        final sectionType = success.section.sharedSectionType;
        Log.debug('shared section type: $sectionType, in page: $pageId');
        return FlowyResult.success(sectionType);
      },
      (failure) {
        Log.error(
          'failed to get shared section type: $failure, in page: $pageId',
        );

        return FlowyResult.failure(failure);
      },
    );
  }
}
