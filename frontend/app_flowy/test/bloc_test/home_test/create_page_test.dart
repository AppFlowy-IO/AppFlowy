import 'package:app_flowy/plugins/board/board.dart';
import 'package:app_flowy/plugins/document/document.dart';
import 'package:app_flowy/plugins/grid/grid.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import '../../util.dart';

void main() {
  late AppFlowyUnitTest testContext;
  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  group(
    '$AppBloc',
    () {
      late AppPB app;
      setUp(() async {
        app = await testContext.createTestApp();
      });

      blocTest<AppBloc, AppState>(
        "Create a document",
        build: () => AppBloc(app: app)..add(const AppEvent.initial()),
        act: (bloc) {
          bloc.add(
              AppEvent.createView("Test document", DocumentPluginBuilder()));
        },
        wait: blocResponseDuration(),
        verify: (bloc) {
          assert(bloc.state.views.length == 1);
          assert(bloc.state.views.last.name == "Test document");
          assert(bloc.state.views.last.layout == ViewLayoutTypePB.Document);
        },
      );

      blocTest<AppBloc, AppState>(
        "Create a grid",
        build: () => AppBloc(app: app)..add(const AppEvent.initial()),
        act: (bloc) {
          bloc.add(AppEvent.createView("Test grid", GridPluginBuilder()));
        },
        wait: blocResponseDuration(),
        verify: (bloc) {
          assert(bloc.state.views.length == 1);
          assert(bloc.state.views.last.name == "Test grid");
          assert(bloc.state.views.last.layout == ViewLayoutTypePB.Grid);
        },
      );

      blocTest<AppBloc, AppState>(
        "Create a Kanban board",
        build: () => AppBloc(app: app)..add(const AppEvent.initial()),
        act: (bloc) {
          bloc.add(AppEvent.createView("Test board", BoardPluginBuilder()));
        },
        wait: const Duration(milliseconds: 100),
        verify: (bloc) {
          assert(bloc.state.views.length == 1);
          assert(bloc.state.views.last.name == "Test board");
          assert(bloc.state.views.last.layout == ViewLayoutTypePB.Board);
        },
      );
    },
  );
}
