import 'package:appflowy/features/share_tab/data/models/share_access_level.dart';
import 'package:appflowy/features/share_tab/data/models/share_role.dart';

/// Represents a user with a role on a shared page.
class SharedUser {
  SharedUser({
    required this.email,
    required this.name,
    required this.role,
    required this.accessLevel,
    this.avatarUrl,
  });

  final String email;

  /// The name of the user.
  final String name;

  /// The role of the user.
  final ShareRole role;

  /// The access level of the user.
  final ShareAccessLevel accessLevel;

  /// The avatar URL of the user.
  ///
  /// if the avatar is not set, it will be the first letter of the name.
  final String? avatarUrl;
}
