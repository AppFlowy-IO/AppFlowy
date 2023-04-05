import 'package:appflowy/plugins/database_view/calendar/calendar.dart';
import 'package:appflowy/plugins/database_view/board/board.dart';
import 'package:appflowy/plugins/database_view/grid/grid.dart';
import 'package:appflowy/plugins/document/document.dart';
import 'package:appflowy/workspace/application/app/app_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../util.dart';

void main() {
  late AppFlowyUnitTest testContext;
  setUpAll(() async {
    testContext = await AppFlowyUnitTest.ensureInitialized();
  });

  test('create a document', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(view: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    bloc.add(AppEvent.createView("Test document", DocumentPluginBuilder()));
    await blocResponseFuture();

    assert(bloc.state.views.length == 1);
    assert(bloc.state.views.last.name == "Test document");
    assert(bloc.state.views.last.layout == ViewLayoutPB.Document);
  });

  test('create a grid', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(view: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    bloc.add(AppEvent.createView("Test grid", GridPluginBuilder()));
    await blocResponseFuture();

    assert(bloc.state.views.length == 1);
    assert(bloc.state.views.last.name == "Test grid");
    assert(bloc.state.views.last.layout == ViewLayoutPB.Grid);
  });

  test('create a kanban', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(view: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    bloc.add(AppEvent.createView("Test board", BoardPluginBuilder()));
    await blocResponseFuture();

    assert(bloc.state.views.length == 1);
    assert(bloc.state.views.last.name == "Test board");
    assert(bloc.state.views.last.layout == ViewLayoutPB.Board);
  });

  test('create a calendar', () async {
    final app = await testContext.createTestApp();
    final bloc = AppBloc(view: app)..add(const AppEvent.initial());
    await blocResponseFuture();

    bloc.add(AppEvent.createView("Test calendar", CalendarPluginBuilder()));
    await blocResponseFuture();

    assert(bloc.state.views.length == 1);
    assert(bloc.state.views.last.name == "Test calendar");
    assert(bloc.state.views.last.layout == ViewLayoutPB.Calendar);
  });
}
