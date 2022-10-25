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
  late List<ViewPB> allViews;
  setUpAll(() async {
    test = await AppFlowyUnitTest.ensureInitialized();

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

  group('$TrashBloc', () {
    late TrashBloc trashBloc;
    late ViewPB deletedView;

    setUpAll(() {});

    setUp(() async {
      trashBloc = TrashBloc()..add(const TrashEvent.initial());
      await blocResponseFuture();
    });

    blocTest<TrashBloc, TrashState>(
      "delete view",
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
      "put back",
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
      "put back all",
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
}
