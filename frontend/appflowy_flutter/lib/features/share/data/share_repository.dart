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
  Future<List<SharedUser>> getUsersInSharedPage({
    required String pageId,
  });

  /// Removes a user from a shared page.
  Future<void> removeUserFromPage({
    required String pageId,
    required String email,
  });

  /// Shares a page with a user, assigning a role.
  ///
  /// If the user is already in the shared page, the role will be updated.
  Future<void> sharePageWithUser({
    required String pageId,
    required String email,
    required ShareRole role,
  });
}

/// The role a user can have on a shared page.
enum ShareRole {
  /// Can view the page only.
  canView,

  /// Can edit the page.
  canEdit,

  /// Full access (edit, share, remove, etc.).
  fullAccess,
}
