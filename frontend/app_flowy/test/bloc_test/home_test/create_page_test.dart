import 'package:app_flowy/plugins/board/board.dart';
import 'package:app_flowy/plugins/document/document.dart';
import 'package:app_flowy/plugins/grid/grid.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../util.dart';

void main() {
  late AppFlowyUnitTest testContext;
  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  test('create a document', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(app: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    bloc.add(AppEvent.createView("Test document", DocumentPluginBuilder()));
    await blocResponseFuture();

    assert(bloc.state.views.length == 1);
    assert(bloc.state.views.last.name == "Test document");
    assert(bloc.state.views.last.layout == ViewLayoutTypePB.Document);
  });

  test('create a grid', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(app: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    bloc.add(AppEvent.createView("Test grid", GridPluginBuilder()));
    await blocResponseFuture();

    assert(bloc.state.views.length == 1);
    assert(bloc.state.views.last.name == "Test grid");
    assert(bloc.state.views.last.layout == ViewLayoutTypePB.Grid);
  });
  test('create a kanban', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(app: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    bloc.add(AppEvent.createView("Test board", BoardPluginBuilder()));
    await blocResponseFuture();

    assert(bloc.state.views.length == 1);
    assert(bloc.state.views.last.name == "Test board");
    assert(bloc.state.views.last.layout == ViewLayoutTypePB.Board);
  });
}
