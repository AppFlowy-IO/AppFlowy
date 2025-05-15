import 'package:appflowy/features/share/data/models/share_role.dart';
import 'package:appflowy/features/share/data/models/shared_user.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

/// Abstract repository for sharing pages with users.
///
/// For example, we're using rust events now, but we can still use the http api
/// for the future.
abstract class ShareRepository {
  /// Gets the list of users and their roles for a shared page.
  Future<FlowyResult<List<SharedUser>, FlowyError>> getUsersInSharedPage({
    required String pageId,
  });

  /// Removes a user from a shared page.
  Future<FlowyResult<void, FlowyError>> removeUserFromPage({
    required String pageId,
    required List<String> emails,
  });

  /// Shares a page with a user, assigning a role.
  ///
  /// If the user is already in the shared page, the role will be updated.
  Future<FlowyResult<void, FlowyError>> sharePageWithUser({
    required String pageId,
    required ShareRole role,
    required List<String> emails,
  });
}
