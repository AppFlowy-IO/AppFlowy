import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

/// Abstract repository for sharing with users.
///
/// For example, we're using rust events now, but we can still use the http api
/// for the future.
abstract class ShareWithUserRepository {
  /// Gets the list of users and their roles for a shared page.
  Future<FlowyResult<SharedUsers, FlowyError>> getSharedUsersInPage({
    required String pageId,
  });

  /// Gets the list of users that are available to be shared with.
  Future<FlowyResult<SharedUsers, FlowyError>> getAvailableSharedUsers({
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

  /// Change the role of a user in a shared page.
  Future<FlowyResult<void, FlowyError>> changeRole({
    required String workspaceId,
    required String email,
    required ShareRole role,
  });
}
