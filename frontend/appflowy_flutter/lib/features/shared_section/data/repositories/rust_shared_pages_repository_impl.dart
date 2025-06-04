import 'package:appflowy/features/shared_section/data/repositories/shared_pages_repository.dart';
import 'package:appflowy/features/shared_section/models/shared_page.dart';
import 'package:appflowy/features/util/extensions.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

class RustSharePagesRepositoryImpl implements SharedPagesRepository {
  @override
  Future<FlowyResult<SharedPages, FlowyError>> getSharedPages() async {
    final result = await FolderEventGetSharedViews().send();
    return result.fold(
      (success) {
        final sharedPages = success.sharedPages;

        Log.info('get shared pages success, len: ${sharedPages.length}');

        return FlowyResult.success(sharedPages);
      },
      (error) {
        Log.error('failed to get shared pages, error: $error');

        return FlowyResult.failure(error);
      },
    );
  }

  @override
  Future<FlowyResult<void, FlowyError>> leaveSharedPage(String pageId) async {
    final user = await UserEventGetUserProfile().send();
    final userEmail = user.fold(
      (success) => success.email,
      (error) => null,
    );

    if (userEmail == null) {
      return FlowyResult.failure(FlowyError(msg: 'User email is null'));
    }

    final request = RemoveUserFromSharedPagePayloadPB(
      viewId: pageId,
      emails: [userEmail],
    );
    final result = await FolderEventRemoveUserFromSharedPage(request).send();

    return result.fold(
      (success) {
        Log.info('remove user($userEmail) from shared page($pageId)');

        return FlowySuccess(success);
      },
      (failure) {
        Log.error(
            'remove user($userEmail) from shared page($pageId): $failure');

        return FlowyFailure(failure);
      },
    );
  }
}
