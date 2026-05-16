import 'package:appflowy/features/shared_section/models/shared_page.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

/// Abstract repository for sharing pages with users.
///
/// For example, we're using rust events now, but we can still use the http api
/// for the future.
abstract class SharedPagesRepository {
  /// Gets the list of users and their roles for a shared page.
  Future<FlowyResult<SharedPages, FlowyError>> getSharedPages();

  /// Removes a shared page from the repository.
  Future<FlowyResult<void, FlowyError>> leaveSharedPage(String pageId);
}
