import 'package:appflowy/plugins/trash/application/trash_bloc.dart';
import 'package:appflowy/workspace/application/app/app_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

class TrashTestContext {
  late ViewPB view;
  late AppBloc appBloc;
  late List<ViewPB> allViews;
  final AppFlowyUnitTest unitTest;

  TrashTestContext(this.unitTest);

  Future<void> initialize() async {
    view = await unitTest.createTestApp();
    appBloc = AppBloc(view: view)..add(const AppEvent.initial());
    await blocResponseFuture();

    appBloc.add(
      const AppEvent.createView(
        "Document 1",
        ViewLayoutPB.Document,
      ),
    );
    await blocResponseFuture();

    appBloc.add(
      const AppEvent.createView(
        "Document 2",
        ViewLayoutPB.Document,
      ),
    );
    await blocResponseFuture();

    appBloc.add(
      const AppEvent.createView(
        "Document 3",
        ViewLayoutPB.Document,
      ),
    );
    await blocResponseFuture();

    allViews = [...appBloc.state.view.childViews];
    assert(allViews.length == 3, 'but receive ${allViews.length}');
  }
}

void main() {
  late AppFlowyUnitTest unitTest;
  setUpAll(() async {
    unitTest = await AppFlowyUnitTest.ensureInitialized();
  });

  // 1. Create three views
  // 2. Delete a view and check the state
  // 3. Delete all views and check the state
  // 4. Put back a view
  // 5. Put back all views

  group('trash test: ', () {
    test('delete a view', () async {
      final context = TrashTestContext(unitTest);
      await context.initialize();
      final trashBloc = TrashBloc()..add(const TrashEvent.initial());
      await blocResponseFuture(millisecond: 200);

      // delete a view
      final deletedView = context.appBloc.state.view.childViews[0];
      context.appBloc.add(AppEvent.deleteView(deletedView.id));
      await blocResponseFuture();
      assert(context.appBloc.state.view.childViews.length == 2);
      assert(trashBloc.state.objects.length == 1);
      assert(trashBloc.state.objects.first.id == deletedView.id);

      // put back
      trashBloc.add(TrashEvent.putback(deletedView.id));
      await blocResponseFuture();
      assert(context.appBloc.state.view.childViews.length == 3);
      assert(trashBloc.state.objects.isEmpty);

      // delete all views
      for (final view in context.allViews) {
        context.appBloc.add(AppEvent.deleteView(view.id));
        await blocResponseFuture();
      }
      expect(trashBloc.state.objects[0].id, context.allViews[0].id);
      expect(trashBloc.state.objects[1].id, context.allViews[1].id);
      expect(trashBloc.state.objects[2].id, context.allViews[2].id);

      // delete a view permanently
      trashBloc.add(TrashEvent.delete(trashBloc.state.objects[0]));
      await blocResponseFuture();
      expect(trashBloc.state.objects.length, 2);

      // delete all view permanently
      trashBloc.add(const TrashEvent.deleteAll());
      await blocResponseFuture();
      assert(
        trashBloc.state.objects.isEmpty,
        "but receive ${trashBloc.state.objects.length}",
      );
    });
  });
}
