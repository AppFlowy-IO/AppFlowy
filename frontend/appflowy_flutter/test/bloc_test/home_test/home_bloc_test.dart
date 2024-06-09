import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/workspace/application/home/home_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  late AppFlowyUnitTest testContext;
  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  test('init home screen', () async {
    final workspaceSetting = await FolderEventGetCurrentWorkspaceSetting()
        .send()
        .then((result) => result.fold((l) => l, (r) => throw Exception()));
    await blocResponseFuture();

    final homeBloc = HomeBloc(workspaceSetting)..add(const HomeEvent.initial());
    await blocResponseFuture();

    assert(homeBloc.state.workspaceSetting.hasLatestView());
  });

  test('open the document', () async {
    final workspaceSetting = await FolderEventGetCurrentWorkspaceSetting()
        .send()
        .then((result) => result.fold((l) => l, (r) => throw Exception()));
    await blocResponseFuture();

    final homeBloc = HomeBloc(workspaceSetting)..add(const HomeEvent.initial());
    await blocResponseFuture();

    final app = await testContext.createWorkspace();
    final appBloc = ViewBloc(view: app)..add(const ViewEvent.initial());
    assert(appBloc.state.lastCreatedView == null);

    appBloc.add(
      const ViewEvent.createView(
        "New document",
        ViewLayoutPB.Document,
        section: ViewSectionPB.Public,
      ),
    );
    await blocResponseFuture();

    assert(appBloc.state.lastCreatedView != null);
    final latestView = appBloc.state.lastCreatedView!;
    final _ = DocumentBloc(documentId: latestView.id)
      ..add(const DocumentEvent.initial());

    await FolderEventSetLatestView(ViewIdPB(value: latestView.id)).send();
    await blocResponseFuture();

    final actual = homeBloc.state.workspaceSetting.latestView.id;
    assert(actual == latestView.id);
  });
}
