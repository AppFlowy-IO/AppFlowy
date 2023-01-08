import 'package:app_flowy/plugins/document/document.dart';
import 'package:app_flowy/plugins/trash/application/trash_bloc.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

class TrashTestContext {
  late AppPB app;
  late AppBloc appBloc;
  late List<ViewPB> allViews;
  final AppFlowyUnitTest unitTest;

  TrashTestContext(this.unitTest);

  Future<void> initialize() async {
    app = await unitTest.createTestApp();
    appBloc = AppBloc(app: app)..add(const AppEvent.initial());

    appBloc.add(AppEvent.createView(
      "Document 1",
      DocumentPluginBuilder(),
    ));
    await blocResponseFuture();

    appBloc.add(AppEvent.createView(
      "Document 2",
      DocumentPluginBuilder(),
    ));
    await blocResponseFuture();

    appBloc.add(
      AppEvent.createView(
        "Document 3",
        DocumentPluginBuilder(),
      ),
    );
    await blocResponseFuture();

    allViews = [...appBloc.state.app.belongings.items];
    assert(allViews.length == 3);
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
      final deletedView = context.appBloc.state.app.belongings.items[0];
      context.appBloc.add(AppEvent.deleteView(deletedView.id));
      await blocResponseFuture();
      assert(context.appBloc.state.app.belongings.items.length == 2);
      assert(trashBloc.state.objects.length == 1);
      assert(trashBloc.state.objects.first.id == deletedView.id);

      // put back
      trashBloc.add(TrashEvent.putback(deletedView.id));
      await blocResponseFuture();
      assert(context.appBloc.state.app.belongings.items.length == 3);
      assert(trashBloc.state.objects.isEmpty);

      // delete all views
      for (final view in context.allViews) {
        context.appBloc.add(AppEvent.deleteView(view.id));
        await blocResponseFuture();
      }
      assert(trashBloc.state.objects[0].id == context.allViews[0].id);
      assert(trashBloc.state.objects[1].id == context.allViews[1].id);
      assert(trashBloc.state.objects[2].id == context.allViews[2].id);

      // delete a view permanently
      trashBloc.add(TrashEvent.delete(trashBloc.state.objects[0]));
      await blocResponseFuture();
      assert(trashBloc.state.objects.length == 2);

      // delete all view permanently
      trashBloc.add(const TrashEvent.deleteAll());
      await blocResponseFuture();
      assert(trashBloc.state.objects.isEmpty);
    });
  });
}
