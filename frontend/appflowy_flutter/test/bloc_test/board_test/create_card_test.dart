import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/board/application/board_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  late AppFlowyBoardTest boardTest;

  setUpAll(() async {
    boardTest = await AppFlowyBoardTest.ensureInitialized();
  });

  test('create kanban baord card', () async {
    final context = await boardTest.createTestBoard();
    final databaseController = DatabaseController(view: context.gridView);
    final boardBloc = BoardBloc(
      view: context.gridView,
      databaseController: databaseController,
    )..add(const BoardEvent.initial());
    await boardResponseFuture();

    final groupId = boardBloc.state.groupIds.first;

    // the group at index 0 is the 'No status' group;
    assert(boardBloc.groupControllers[groupId]!.group.rows.isEmpty);
    assert(
      boardBloc.state.groupIds.length == 4,
      'but receive ${boardBloc.state.groupIds.length}',
    );

    boardBloc.add(BoardEvent.createBottomRow(boardBloc.state.groupIds[0]));
    await boardResponseFuture();

    assert(
      boardBloc.groupControllers[groupId]!.group.rows.length == 1,
      'but receive ${boardBloc.groupControllers[groupId]!.group.rows.length}',
    );
  });
}
