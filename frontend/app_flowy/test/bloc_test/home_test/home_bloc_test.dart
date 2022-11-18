import 'package:app_flowy/plugins/document/application/doc_bloc.dart';
import 'package:app_flowy/plugins/document/document.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  late AppFlowyUnitTest testContext;
  late WorkspaceSettingPB workspaceSetting;
  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  setUp(() async {
    workspaceSetting = await FolderEventReadCurrentWorkspace()
        .send()
        .then((result) => result.fold((l) => l, (r) => throw Exception()));
    await blocResponseFuture();
  });

  group('$HomeBloc', () {
    blocTest<HomeBloc, HomeState>(
      "initial",
      build: () => HomeBloc(testContext.userProfile, workspaceSetting)
        ..add(const HomeEvent.initial()),
      wait: blocResponseDuration(),
      verify: (bloc) {
        assert(bloc.state.workspaceSetting.hasLatestView());
      },
    );
  });

  group('$HomeBloc', () {
    late AppPB app;
    late ViewPB latestCreatedView;
    late HomeBloc homeBloc;
    setUpAll(() async {
      app = await testContext.createTestApp();
      homeBloc = HomeBloc(testContext.userProfile, workspaceSetting)
        ..add(const HomeEvent.initial());
    });

    blocTest<AppBloc, AppState>(
      "create a document view",
      build: () => AppBloc(app: app)..add(const AppEvent.initial()),
      act: (bloc) async {
        bloc.add(AppEvent.createView("New document", DocumentPluginBuilder()));
      },
      wait: blocResponseDuration(),
      verify: (bloc) {
        latestCreatedView = bloc.state.views.last;
      },
    );

    blocTest<DocumentBloc, DocumentState>(
      "open the document",
      build: () => DocumentBloc(view: latestCreatedView)
        ..add(const DocumentEvent.initial()),
      wait: blocResponseDuration(),
    );

    test('check the latest view is the document', () async {
      assert(homeBloc.state.workspaceSetting.latestView.id ==
          latestCreatedView.id);
    });
  });
}
