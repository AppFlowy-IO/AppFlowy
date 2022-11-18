import 'package:app_flowy/plugins/document/document.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/view/view_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  late AppFlowyUnitTest test;
  setUpAll(() async {
    test = await AppFlowyUnitTest.ensureInitialized();
  });

  group('$ViewBloc', () {
    late AppBloc appBloc;

    setUpAll(() async {
      final app = await test.createTestApp();
      appBloc = AppBloc(app: app)..add(const AppEvent.initial());
      appBloc.add(AppEvent.createView(
        "Test document",
        DocumentPluginBuilder(),
      ));
      await blocResponseFuture();
    });

    blocTest<ViewBloc, ViewState>(
      "rename view",
      build: () => ViewBloc(view: appBloc.state.views.first)
        ..add(const ViewEvent.initial()),
      act: (bloc) {
        bloc.add(const ViewEvent.rename('Hello world'));
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.view.name == "Hello world");
      },
    );

    blocTest<ViewBloc, ViewState>(
      "duplicate view",
      build: () => ViewBloc(view: appBloc.state.views.first)
        ..add(const ViewEvent.initial()),
      act: (bloc) {
        bloc.add(const ViewEvent.duplicate());
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(appBloc.state.views.length == 2);
      },
    );

    blocTest<ViewBloc, ViewState>(
      "delete view",
      build: () => ViewBloc(view: appBloc.state.views.first)
        ..add(const ViewEvent.initial()),
      act: (bloc) {
        bloc.add(const ViewEvent.delete());
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(appBloc.state.views.length == 1);
      },
    );
  });
}
