import 'package:app_flowy/plugins/board/board.dart';
import 'package:app_flowy/plugins/doc/document.dart';
import 'package:app_flowy/plugins/grid/grid.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_view_section_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import '../../util.dart';

void main() {
  late AppFlowyUnitTest test;
  setUpAll(() async {
    test = await AppFlowyUnitTest.ensureInitialized();
  });

  group(
    '$AppBloc',
    () {
      late AppPB app;
      setUp(() async {
        app = await test.createTestApp();
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

  group('$AppBloc', () {
    late AppPB app;
    setUpAll(() async {
      app = await test.createTestApp();
    });

    blocTest<AppBloc, AppState>(
      "rename the app",
      build: () => AppBloc(app: app)..add(const AppEvent.initial()),
      wait: blocResponseDuration(),
      act: (bloc) => bloc.add(const AppEvent.rename('Hello world')),
      verify: (bloc) {
        assert(bloc.state.app.name == 'Hello world');
      },
    );

    blocTest<AppBloc, AppState>(
      "delete the app",
      build: () => AppBloc(app: app)..add(const AppEvent.initial()),
      wait: blocResponseDuration(),
      act: (bloc) => bloc.add(const AppEvent.delete()),
      verify: (bloc) async {
        final apps = await test.loadApps();
        assert(apps.where((element) => element.id == app.id).isEmpty);
      },
    );
  });

  group('$AppBloc', () {
    late ViewPB view;
    late AppPB app;
    setUpAll(() async {
      app = await test.createTestApp();
    });

    blocTest<AppBloc, AppState>(
      "create a document",
      build: () => AppBloc(app: app)..add(const AppEvent.initial()),
      act: (bloc) {
        bloc.add(AppEvent.createView("Test document", DocumentPluginBuilder()));
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.views.length == 1);
        view = bloc.state.views.last;
      },
    );

    blocTest<AppBloc, AppState>(
      "delete the document",
      build: () => AppBloc(app: app)..add(const AppEvent.initial()),
      act: (bloc) => bloc.add(AppEvent.deleteView(view.id)),
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.views.isEmpty);
      },
    );
  });

  group('$AppBloc', () {
    late AppPB app;
    setUpAll(() async {
      app = await test.createTestApp();
    });
    blocTest<AppBloc, AppState>(
      "create documents' order test",
      build: () => AppBloc(app: app)..add(const AppEvent.initial()),
      act: (bloc) async {
        bloc.add(AppEvent.createView("1", DocumentPluginBuilder()));
        await blocResponseFuture();
        bloc.add(AppEvent.createView("2", DocumentPluginBuilder()));
        await blocResponseFuture();
        bloc.add(AppEvent.createView("3", DocumentPluginBuilder()));
        await blocResponseFuture();
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.views[0].name == '1');
        assert(bloc.state.views[1].name == '2');
        assert(bloc.state.views[2].name == '3');
      },
    );
  });

  group('$AppBloc', () {
    late AppPB app;
    setUpAll(() async {
      app = await test.createTestApp();
    });
    blocTest<AppBloc, AppState>(
      "reorder documents",
      build: () => AppBloc(app: app)..add(const AppEvent.initial()),
      act: (bloc) async {
        bloc.add(AppEvent.createView("1", DocumentPluginBuilder()));
        await blocResponseFuture();
        bloc.add(AppEvent.createView("2", DocumentPluginBuilder()));
        await blocResponseFuture();
        bloc.add(AppEvent.createView("3", DocumentPluginBuilder()));
        await blocResponseFuture();

        final appViewData = AppViewDataContext(appId: app.id);
        appViewData.views = bloc.state.views;
        final viewSectionBloc = ViewSectionBloc(
          appViewData: appViewData,
        )..add(const ViewSectionEvent.initial());
        await blocResponseFuture();

        viewSectionBloc.add(const ViewSectionEvent.moveView(0, 2));
        await blocResponseFuture();
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.views[0].name == '2');
        assert(bloc.state.views[1].name == '3');
        assert(bloc.state.views[2].name == '1');
      },
    );
  });
}
