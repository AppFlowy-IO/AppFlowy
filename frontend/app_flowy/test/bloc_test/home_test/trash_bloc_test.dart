import 'package:app_flowy/plugins/doc/document.dart';
import 'package:app_flowy/plugins/trash/application/trash_bloc.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  late AppFlowyUnitTest test;
  late AppPB app;
  late AppBloc appBloc;
  late TrashBloc trashBloc;
  setUpAll(() async {
    test = await AppFlowyUnitTest.ensureInitialized();
  });

  // 1. Create three views
  // 2. Delete a view and check the state
  // 3. Delete all views and check the state
  // 4. Put back a view
  // 5. Put back all views
  group('$TrashBloc', () {
    late ViewPB deletedView;
    late List<ViewPB> allViews;
    setUpAll(() async {
      /// Create a new app with three documents
      app = await test.createTestApp();
      appBloc = AppBloc(app: app)
        ..add(const AppEvent.initial())
        ..add(AppEvent.createView(
          "Document 1",
          DocumentPluginBuilder(),
        ))
        ..add(AppEvent.createView(
          "Document 2",
          DocumentPluginBuilder(),
        ))
        ..add(
          AppEvent.createView(
            "Document 3",
            DocumentPluginBuilder(),
          ),
        );
      await blocResponseFuture(millisecond: 200);
      allViews = [...appBloc.state.app.belongings.items];
      assert(allViews.length == 3);
    });

    setUp(() async {
      trashBloc = TrashBloc()..add(const TrashEvent.initial());
      await blocResponseFuture();
    });

    blocTest<TrashBloc, TrashState>(
      "delete a view",
      build: () => trashBloc,
      act: (bloc) async {
        deletedView = appBloc.state.app.belongings.items[0];
        appBloc.add(AppEvent.deleteView(deletedView.id));
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(appBloc.state.app.belongings.items.length == 2);
        assert(bloc.state.objects.length == 1);
        assert(bloc.state.objects.first.id == deletedView.id);
      },
    );

    blocTest<TrashBloc, TrashState>(
      "delete all views",
      build: () => trashBloc,
      act: (bloc) async {
        for (final view in appBloc.state.app.belongings.items) {
          appBloc.add(AppEvent.deleteView(view.id));
          await blocResponseFuture();
        }
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.objects[0].id == allViews[0].id);
        assert(bloc.state.objects[1].id == allViews[1].id);
        assert(bloc.state.objects[2].id == allViews[2].id);
      },
    );
    blocTest<TrashBloc, TrashState>(
      "put back a trash",
      build: () => trashBloc,
      act: (bloc) async {
        bloc.add(TrashEvent.putback(allViews[0].id));
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(appBloc.state.app.belongings.items.length == 1);
        assert(bloc.state.objects.length == 2);
      },
    );
    blocTest<TrashBloc, TrashState>(
      "put back all trash",
      build: () => trashBloc,
      act: (bloc) async {
        bloc.add(const TrashEvent.restoreAll());
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(appBloc.state.app.belongings.items.length == 3);
        assert(bloc.state.objects.isEmpty);
      },
    );
    //
  });

  // 1. Create three views
  // 2. Delete a trash permanently and check the state
  // 3. Delete all views permanently
  group('$TrashBloc', () {
    setUpAll(() async {
      /// Create a new app with three documents
      app = await test.createTestApp();
      appBloc = AppBloc(app: app)
        ..add(const AppEvent.initial())
        ..add(AppEvent.createView(
          "Document 1",
          DocumentPluginBuilder(),
        ))
        ..add(AppEvent.createView(
          "Document 2",
          DocumentPluginBuilder(),
        ))
        ..add(
          AppEvent.createView(
            "Document 3",
            DocumentPluginBuilder(),
          ),
        );
      await blocResponseFuture(millisecond: 200);
    });

    setUp(() async {
      trashBloc = TrashBloc()..add(const TrashEvent.initial());
      await blocResponseFuture();
    });

    blocTest<TrashBloc, TrashState>(
      "delete a view permanently",
      build: () => trashBloc,
      act: (bloc) async {
        final view = appBloc.state.app.belongings.items[0];
        appBloc.add(AppEvent.deleteView(view.id));
        await blocResponseFuture();

        trashBloc.add(TrashEvent.delete(trashBloc.state.objects[0]));
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(appBloc.state.app.belongings.items.length == 2);
        assert(bloc.state.objects.isEmpty);
      },
    );
    blocTest<TrashBloc, TrashState>(
      "delete all view permanently",
      build: () => trashBloc,
      act: (bloc) async {
        for (final view in appBloc.state.app.belongings.items) {
          appBloc.add(AppEvent.deleteView(view.id));
          await blocResponseFuture();
        }
        trashBloc.add(const TrashEvent.deleteAll());
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(appBloc.state.app.belongings.items.isEmpty);
        assert(bloc.state.objects.isEmpty);
      },
    );
  });
}
