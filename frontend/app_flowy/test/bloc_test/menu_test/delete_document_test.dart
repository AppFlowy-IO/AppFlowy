import 'package:app_flowy/plugins/doc/document.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import '../../util.dart';

void main() {
  late AppFlowyUnitTest test;
  late AppPB app;
  late ViewPB view;

  setUpAll(() async {
    test = await AppFlowyUnitTest.ensureInitialized();
    app = await test.createTestApp();
  });

  group('AppBloc delete document test:', () {
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
    );
    blocTest<AppBloc, AppState>(
      "verify the document is exist",
      build: () => AppBloc(app: app)..add(const AppEvent.initial()),
      act: (bloc) => bloc.add(const AppEvent.loadViews()),
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.views.isEmpty);
      },
    );
  });
}
