import 'package:appflowy/features/mension_person/data/cache/person_list_cache.dart';
import 'package:appflowy/features/mension_person/data/repositories/mention_repository.dart';
import 'package:appflowy/features/mension_person/data/repositories/mock_mention_repository.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../../util.dart';
import '../../../../widget_test/get_it_set_up.dart';

void main() {
  const workspaceId = 'test_workspace_id';
  late MentionRepository repository;
  late MentionBloc bloc;

  setUp(() {
    setUpGetIt();
    GetIt.I.registerSingleton<PersonListCache>(PersonListCache());
    repository = MockMentionRepository();
    bloc = MentionBloc(repository, workspaceId, false, getIt<PersonListCache>())
      ..add(MentionEvent.init());
  });

  tearDown(() async {
    tearDownGetIt();
    await bloc.close();
  });

  group('Mention Menu', () {
    test('toggle send notification', () async {
      expect(bloc.state.sendNotification, isFalse);
      bloc.add(const MentionEvent.toggleSendNotification());
      await blocResponseFuture();
      expect(bloc.state.sendNotification, isTrue);
    });

    test('get person list', () async {
      expect(bloc.state.persons, isEmpty);
      bloc.add(const MentionEvent.getPersons(workspaceId: workspaceId));
      await blocResponseFuture();
      expect(bloc.state.persons, isNotEmpty);
    });

    test('toogle show more', () async {
      expect(bloc.state.showMorePage, isFalse);
      expect(bloc.state.showMorePersons, isFalse);
      bloc.add(const MentionEvent.showMorePages(''));
      bloc.add(const MentionEvent.showMorePersons(''));
      await blocResponseFuture();
      expect(bloc.state.showMorePage, isTrue);
      expect(bloc.state.showMorePersons, isTrue);
    });

    test('add and remove visible items', () async {
      const testId = 'test_id';
      expect(bloc.state.visibleItems, isEmpty);
      bloc.add(const MentionEvent.addVisibleItem(testId));
      await blocResponseFuture();
      expect(bloc.state.visibleItems.first, testId);
      bloc.add(const MentionEvent.removeVisibleItem(testId));
      await blocResponseFuture();
      expect(bloc.state.visibleItems, isEmpty);
    });

    test('change selected item', () async {
      const testId = 'test_id', testId2 = 'test_id_2';
      expect(bloc.state.selectedId, '');
      bloc.add(const MentionEvent.selectItem(testId));
      await blocResponseFuture();
      expect(bloc.state.selectedId, testId);
      bloc.add(const MentionEvent.selectItem(testId2));
      await blocResponseFuture();
      expect(bloc.state.selectedId, testId2);
    });
  });
}
