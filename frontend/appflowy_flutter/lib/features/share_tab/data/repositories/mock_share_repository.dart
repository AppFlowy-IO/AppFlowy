import 'dart:math';

import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'share_repository.dart';

class MockShareRepository extends ShareRepository {
  MockShareRepository();

  final List<SharedUser> _sharedUsers = [
    SharedUser(
      email: 'lucas.xu@appflowy.io',
      name: 'Lucas Xu',
      accessLevel: ShareAccessLevel.readOnly,
      role: ShareRole.guest,
      avatarUrl: 'https://avatar.iran.liara.run/public',
    ),
    SharedUser(
      email: 'vivian@appflowy.io',
      name: 'Vivian Wang',
      accessLevel: ShareAccessLevel.readAndWrite,
      role: ShareRole.member,
      avatarUrl: 'https://avatar.iran.liara.run/public/girl',
    ),
    SharedUser(
      email: 'shuheng@appflowy.io',
      name: 'Shuheng',
      accessLevel: ShareAccessLevel.fullAccess,
      role: ShareRole.owner,
      avatarUrl: 'https://avatar.iran.liara.run/public/boy',
    ),
    SharedUser(
      email: 'guest_user_1@appflowy.io',
      name: 'Guest User 1',
      accessLevel: ShareAccessLevel.readOnly,
      role: ShareRole.guest,
      avatarUrl: 'https://avatar.iran.liara.run/public/boy/10',
    ),
    SharedUser(
      email: 'guest_user_2@appflowy.io',
      name: 'Guest User 2',
      accessLevel: ShareAccessLevel.readOnly,
      role: ShareRole.owner,
      avatarUrl: 'https://avatar.iran.liara.run/public/boy/11',
    ),
    SharedUser(
      email: 'member_user_1@appflowy.io',
      name: 'Member User 1',
      accessLevel: ShareAccessLevel.readAndWrite,
      role: ShareRole.member,
      avatarUrl: 'https://avatar.iran.liara.run/public/boy/12',
    ),
    SharedUser(
      email: 'member_user_2@appflowy.io',
      name: 'Member User 2',
      accessLevel: ShareAccessLevel.readAndWrite,
      role: ShareRole.member,
      avatarUrl: 'https://avatar.iran.liara.run/public/boy/13',
    ),
  ];

  final List<SharedUser> _availableSharedUsers = [
    SharedUser(
      email: 'guest_email@appflowy.io',
      name: 'Guest',
      accessLevel: ShareAccessLevel.readOnly,
      role: ShareRole.guest,
      avatarUrl: 'https://avatar.iran.liara.run/public/boy/28',
    ),
    SharedUser(
      email: 'richard@appflowy.io',
      name: 'Richard',
      accessLevel: ShareAccessLevel.readAndWrite,
      role: ShareRole.member,
      avatarUrl: 'https://avatar.iran.liara.run/public/boy/28',
    ),
  ];

  @override
  Future<FlowyResult<List<SharedUser>, FlowyError>> getSharedUsersInPage({
    required String pageId,
  }) async {
    return FlowySuccess(_sharedUsers);
  }

  @override
  Future<FlowyResult<void, FlowyError>> removeSharedUserFromPage({
    required String pageId,
    required List<String> emails,
  }) async {
    for (final email in emails) {
      _sharedUsers.removeWhere((user) => user.email == email);
    }

    return FlowySuccess(null);
  }

  @override
  Future<FlowyResult<void, FlowyError>> sharePageWithUser({
    required String pageId,
    required ShareAccessLevel accessLevel,
    required List<String> emails,
  }) async {
    for (final email in emails) {
      final index = _sharedUsers.indexWhere((user) => user.email == email);
      if (index != -1) {
        // Update access level if user exists
        final user = _sharedUsers[index];
        _sharedUsers[index] = SharedUser(
          name: user.name,
          email: user.email,
          accessLevel: accessLevel,
          role: user.role,
          avatarUrl: user.avatarUrl,
        );
      } else {
        // Add new user
        _sharedUsers.add(
          SharedUser(
            name: email.split('@').first,
            email: email,
            accessLevel: accessLevel,
            role: ShareRole.guest,
            avatarUrl:
                'https://avatar.iran.liara.run/public/${Random().nextInt(100)}',
          ),
        );
      }
    }

    return FlowySuccess(null);
  }

  @override
  Future<FlowyResult<List<SharedUser>, FlowyError>> getAvailableSharedUsers({
    required String pageId,
  }) async {
    return FlowySuccess([
      ..._sharedUsers,
      ..._availableSharedUsers,
    ]);
  }
}
