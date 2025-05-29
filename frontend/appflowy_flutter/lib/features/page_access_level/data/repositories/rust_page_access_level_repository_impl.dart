import 'package:appflowy/features/page_access_level/data/repositories/page_access_level_repository.dart';
import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy/features/util/extensions.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
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
    final user = await UserBackendService.getCurrentUserProfile();
    final email = user.fold(
      (s) => s.email,
      (f) => null,
    );
    if (email == null) {
      return FlowyResult.failure(
        FlowyError(
          code: ErrorCode.Internal,
          msg: 'User not found',
        ),
      );
    }

    final request = GetSharedUsersPayloadPB(
      viewId: pageId,
    );
    final result = await FolderEventGetSharedUsers(request).send();
    return result.fold(
      (success) {
        Log.debug('get shared users: $success');
        final accessLevel = success.items
            .firstWhereOrNull(
              (item) => item.email == email,
            )
            ?.accessLevel
            .shareAccessLevel;
        return FlowyResult.success(accessLevel ?? ShareAccessLevel.readOnly);
      },
      (failure) {
        Log.error('getUsersInSharedPage: $failure');
        return FlowyResult.failure(failure);
      },
    );
  }
}
