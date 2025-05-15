import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

/// Represents a user with a role on a shared page.
class SharedUser {
  SharedUser({
    required this.email,
    required this.role,
  });

  final String email;
  final ShareRole role;
}

/// Abstract repository for sharing pages with users.
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

/// The role a user can have on a shared page.
enum ShareRole {
  /// Can view the page only.
  readOnly,

  /// Can read and comment on the page.
  readAndComment,

  /// Can read and write to the page.
  readAndWrite,

  /// Full access (edit, share, remove, etc.) and can add new users.
  fullAccess,
}
