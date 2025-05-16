import 'package:appflowy/features/share/data/models/share_role.dart';
import 'package:appflowy/features/share/data/models/shared_user.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'share_repository.dart';

class MockShareRepository extends ShareRepository {
  MockShareRepository();

  final List<SharedUser> _sharedUsers = [
    SharedUser(
      email: 'lucas.xu@appflowy.io',
      name: 'Lucas Xu',
      role: ShareRole.readOnly,
      avatarUrl: 'https://avatar.iran.liara.run/public',
    ),
    SharedUser(
      email: 'vivian@appflowy.io',
      name: 'Vivian Wang',
      role: ShareRole.readAndWrite,
      avatarUrl: 'https://avatar.iran.liara.run/public/boy',
    ),
    SharedUser(
      email: 'shuheng@appflowy.io',
      name: 'Shuheng',
      role: ShareRole.fullAccess,
      avatarUrl: 'https://avatar.iran.liara.run/public/boy',
    ),
  ];

  @override
  Future<FlowyResult<List<SharedUser>, FlowyError>> getUsersInSharedPage({
    required String pageId,
  }) async {
    return FlowySuccess(_sharedUsers);
  }

  @override
  Future<FlowyResult<void, FlowyError>> removeUserFromPage({
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
    required ShareRole role,
    required List<String> emails,
  }) async {
    for (final email in emails) {
      _sharedUsers.add(
        SharedUser(
          email: email,
          name: email,
          role: role,
          avatarUrl:
              'https://avatar.iran.liara.run/public/${email.hashCode % 2 == 0 ? 'boy' : 'girl'}',
        ),
      );
    }

    return FlowySuccess(null);
  }
}
