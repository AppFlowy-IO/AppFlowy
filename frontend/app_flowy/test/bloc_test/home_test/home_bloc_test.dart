import 'package:app_flowy/plugins/document/application/doc_bloc.dart';
import 'package:app_flowy/plugins/document/document.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  late AppFlowyUnitTest testContext;
  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  test('initi home screen', () async {
    final workspaceSetting = await FolderEventReadCurrentWorkspace()
        .send()
        .then((result) => result.fold((l) => l, (r) => throw Exception()));
    await blocResponseFuture();

    final homeBloc = HomeBloc(testContext.userProfile, workspaceSetting)
      ..add(const HomeEvent.initial());
    await blocResponseFuture();

    assert(homeBloc.state.workspaceSetting.hasLatestView());
  });

  test('open the document', () async {
    final workspaceSetting = await FolderEventReadCurrentWorkspace()
        .send()
        .then((result) => result.fold((l) => l, (r) => throw Exception()));
    await blocResponseFuture();

    final homeBloc = HomeBloc(testContext.userProfile, workspaceSetting)
      ..add(const HomeEvent.initial());
    await blocResponseFuture();

    final app = await testContext.createTestApp();
    final appBloc = AppBloc(app: app)..add(const AppEvent.initial());
    assert(appBloc.state.latestCreatedView == null);

    appBloc.add(AppEvent.createView("New document", DocumentPluginBuilder()));
    await blocResponseFuture();

    assert(appBloc.state.latestCreatedView != null);
    final latestView = appBloc.state.latestCreatedView!;
    final _ = DocumentBloc(view: latestView)
      ..add(const DocumentEvent.initial());
    await blocResponseFuture();

    assert(homeBloc.state.workspaceSetting.latestView.id == latestView.id);
  });
}
