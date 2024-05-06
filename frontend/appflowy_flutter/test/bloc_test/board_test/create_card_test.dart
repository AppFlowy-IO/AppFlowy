import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
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
      databaseController: databaseController,
    )..add(const BoardEvent.initial());
    await boardResponseFuture();

    List<String> groupIds = boardBloc.state.maybeMap(
      orElse: () => [],
      ready: (value) => value.groupIds,
    );
    String lastGroupId = groupIds.last;

    // the group at index 3 is the 'No status' group;
    assert(boardBloc.groupControllers[lastGroupId]!.group.rows.isEmpty);
    assert(
      groupIds.length == 4,
      'but receive ${groupIds.length}',
    );

    boardBloc.add(BoardEvent.createBottomRow(groupIds[3], ""));
    await boardResponseFuture();

    groupIds = boardBloc.state.maybeMap(
      orElse: () => [],
      ready: (value) => value.groupIds,
    );
    lastGroupId = groupIds.last;

    assert(
      boardBloc.groupControllers[lastGroupId]!.group.rows.length == 1,
      'but receive ${boardBloc.groupControllers[lastGroupId]!.group.rows.length}',
    );
  });
}
