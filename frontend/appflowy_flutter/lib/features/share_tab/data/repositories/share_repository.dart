import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy/features/share_tab/data/models/shared_user.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

/// Abstract repository for sharing pages with users.
///
/// For example, we're using rust events now, but we can still use the http api
/// for the future.
abstract class ShareRepository {
  /// Gets the list of users and their roles for a shared page.
  Future<FlowyResult<List<SharedUser>, FlowyError>> getSharedUsersInPage({
    required String pageId,
  });

  /// Gets the list of users that are available to be shared with.
  Future<FlowyResult<List<SharedUser>, FlowyError>> getAvailableSharedUsers({
    required String pageId,
  });

  /// Removes a user from a shared page.
  Future<FlowyResult<void, FlowyError>> removeSharedUserFromPage({
    required String pageId,
    required List<String> emails,
  });

  /// Shares a page with a user, assigning a role.
  ///
  /// If the user is already in the shared page, the access level will be updated.
  Future<FlowyResult<void, FlowyError>> sharePageWithUser({
    required String pageId,
    required ShareAccessLevel accessLevel,
    required List<String> emails,
  });
}
