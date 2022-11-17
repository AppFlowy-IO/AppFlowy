import 'package:app_flowy/plugins/document/application/doc_bloc.dart';
import 'package:app_flowy/plugins/document/document.dart';
import 'package:app_flowy/plugins/grid/grid.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_view_section_bloc.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../util.dart';

void main() {
  late AppFlowyUnitTest testContext;
  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  test('rename app test', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(app: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    bloc.add(const AppEvent.rename('Hello world'));
    await blocResponseFuture();

    assert(bloc.state.app.name == 'Hello world');
  });

  test('delete ap test', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(app: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    bloc.add(const AppEvent.delete());
    await blocResponseFuture();

    final apps = await testContext.loadApps();
    assert(apps.where((element) => element.id == app.id).isEmpty);
  });

  test('create documents in order', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(app: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    bloc.add(AppEvent.createView("1", DocumentPluginBuilder()));
    await blocResponseFuture();
    bloc.add(AppEvent.createView("2", DocumentPluginBuilder()));
    await blocResponseFuture();
    bloc.add(AppEvent.createView("3", DocumentPluginBuilder()));
    await blocResponseFuture();

    assert(bloc.state.views[0].name == '1');
    assert(bloc.state.views[1].name == '2');
    assert(bloc.state.views[2].name == '3');
  });

  test('reorder documents test', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(app: app)..add(const AppEvent.initial());
    await blocResponseFuture();

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

    assert(bloc.state.views[0].name == '2');
    assert(bloc.state.views[1].name == '3');
    assert(bloc.state.views[2].name == '1');
  });

  test('open latest view test', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(app: app)..add(const AppEvent.initial());
    await blocResponseFuture();
    assert(
      bloc.state.latestCreatedView == null,
      "assert initial latest create view is null after initialize",
    );

    bloc.add(AppEvent.createView("1", DocumentPluginBuilder()));
    await blocResponseFuture();
    assert(
      bloc.state.latestCreatedView!.id == bloc.state.views.last.id,
      "create a view and assert the latest create view is this view",
    );

    bloc.add(AppEvent.createView("2", DocumentPluginBuilder()));
    await blocResponseFuture();
    assert(
      bloc.state.latestCreatedView!.id == bloc.state.views.last.id,
      "create a view and assert the latest create view is this view",
    );
  });

  test('open latest documents test', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(app: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    bloc.add(AppEvent.createView("document 1", DocumentPluginBuilder()));
    await blocResponseFuture();
    final document1 = bloc.state.latestCreatedView;
    assert(document1!.name == "document 1");

    bloc.add(AppEvent.createView("document 2", DocumentPluginBuilder()));
    await blocResponseFuture();
    final document2 = bloc.state.latestCreatedView;
    assert(document2!.name == "document 2");

    // Open document 1
    // ignore: unused_local_variable
    final documentBloc = DocumentBloc(view: document1!)
      ..add(const DocumentEvent.initial());
    await blocResponseFuture();

    final workspaceSetting = await FolderEventReadCurrentWorkspace()
        .send()
        .then((result) => result.fold((l) => l, (r) => throw Exception()));
    workspaceSetting.latestView.id == document1.id;
  });

  test('open latest grid test', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(app: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    bloc.add(AppEvent.createView("grid 1", GridPluginBuilder()));
    await blocResponseFuture();
    final grid1 = bloc.state.latestCreatedView;
    assert(grid1!.name == "grid 1");

    bloc.add(AppEvent.createView("grid 2", GridPluginBuilder()));
    await blocResponseFuture();
    final grid2 = bloc.state.latestCreatedView;
    assert(grid2!.name == "grid 2");

    var workspaceSetting = await FolderEventReadCurrentWorkspace()
        .send()
        .then((result) => result.fold((l) => l, (r) => throw Exception()));
    workspaceSetting.latestView.id == grid1!.id;

    // Open grid 1
    // ignore: unused_local_variable
    final documentBloc = DocumentBloc(view: grid1)
      ..add(const DocumentEvent.initial());
    await blocResponseFuture();

    workspaceSetting = await FolderEventReadCurrentWorkspace()
        .send()
        .then((result) => result.fold((l) => l, (r) => throw Exception()));
    workspaceSetting.latestView.id == grid1.id;
  });
}
