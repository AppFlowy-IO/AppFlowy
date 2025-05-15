import 'package:appflowy/features/share/data/models/share_role.dart';

/// Represents a user with a role on a shared page.
class SharedUser {
  SharedUser({
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  final String email;
  final String name;
  final ShareRole role;
  final String? avatarUrl;
}
