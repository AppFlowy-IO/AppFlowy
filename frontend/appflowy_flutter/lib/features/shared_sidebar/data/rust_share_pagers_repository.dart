import 'package:appflowy/features/shared_sidebar/data/share_pages_repository.dart';
import 'package:appflowy/features/shared_sidebar/models/shared_page.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:appflowy/features/shared_sidebar/util/extensions.dart';

class RustSharePagesRepository implements SharePagesRepository {
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
}
