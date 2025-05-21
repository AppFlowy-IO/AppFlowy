import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/data/repositories/local_share_with_user_repository.dart';
import 'package:appflowy/features/share_tab/logic/share_with_user_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pageId = 'test_page_id';
  const workspaceId = 'test_workspace_id';
  late LocalShareWithUserRepository repository;
  late ShareWithUserBloc bloc;

  setUp(() {
    repository = LocalShareWithUserRepository();
    bloc = ShareWithUserBloc(
      repository: repository,
      pageId: pageId,
      workspaceId: workspaceId,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  const email = 'lucas.xu@appflowy.io';

  group('ShareWithUserBloc', () {
    blocTest<ShareWithUserBloc, ShareWithUserState>(
      'shares page with user',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const ShareWithUserEvent.share(
          emails: [email],
          accessLevel: ShareAccessLevel.readOnly,
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        // First state: shareResult is null
        isA<ShareWithUserState>()
            .having((s) => s.shareResult, 'shareResult', isNull),
        // Second state: shareResult is Success
        isA<ShareWithUserState>()
            .having((s) => s.shareResult, 'shareResult', isNotNull),
        // Third state: users updated, shareResult still Success
        isA<ShareWithUserState>().having(
          (s) => s.users.any((u) => u.email == email),
          'users contains new user',
          isTrue,
        ),
      ],
    );

    blocTest<ShareWithUserBloc, ShareWithUserState>(
      'removes user from page',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const ShareWithUserEvent.remove(
          emails: [email],
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        // First state: removeResult is null
        isA<ShareWithUserState>()
            .having((s) => s.removeResult, 'removeResult', isNull),
        // Second state: removeResult is Success
        isA<ShareWithUserState>()
            .having((s) => s.removeResult, 'removeResult', isNotNull),
        // Third state: users updated, removeResult still Success
        isA<ShareWithUserState>().having(
          (s) => s.users.any((u) => u.email == email),
          'users contains removed user',
          isFalse,
        ),
      ],
    );

    blocTest<ShareWithUserBloc, ShareWithUserState>(
      'updates access level for user',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const ShareWithUserEvent.updateAccessLevel(
          email: email,
          accessLevel: ShareAccessLevel.fullAccess,
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        // First state: updateAccessLevelResult is null
        isA<ShareWithUserState>().having(
          (s) => s.updateAccessLevelResult,
          'updateAccessLevelResult',
          isNull,
        ),
        // Second state: updateAccessLevelResult is Success
        isA<ShareWithUserState>().having(
          (s) => s.updateAccessLevelResult,
          'updateAccessLevelResult',
          isNotNull,
        ),
        // Third state: users updated, vivian's access level is fullAccess
        isA<ShareWithUserState>().having(
          (s) => s.users.firstWhere((u) => u.email == email).accessLevel,
          'vivian accessLevel',
          ShareAccessLevel.fullAccess,
        ),
      ],
    );
  });
}
