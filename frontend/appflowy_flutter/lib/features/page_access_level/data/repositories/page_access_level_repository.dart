import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

/// Abstract repository for managing view lock status.
///
/// For example, we're using rust events now, but we can still use the http api
/// for the future.
abstract class PageAccessLevelRepository {
  /// Gets the current view from the backend.
  Future<FlowyResult<ViewPB, FlowyError>> getView(String pageId);

  /// Locks the view.
  Future<FlowyResult<void, FlowyError>> lockView(String pageId);

  /// Unlocks the view.
  Future<FlowyResult<void, FlowyError>> unlockView(String pageId);

  /// Gets the access level of the current user.
  Future<FlowyResult<ShareAccessLevel, FlowyError>> getAccessLevel(
    String pageId,
  );

  /// Gets the section type of the shared section.
  Future<FlowyResult<SharedSectionType, FlowyError>> getSectionType(
    String pageId,
  );

  /// Get current workspace
  Future<FlowyResult<UserWorkspacePB, FlowyError>> getCurrentWorkspace();
}
