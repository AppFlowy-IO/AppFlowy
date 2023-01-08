import 'package:app_flowy/plugins/board/application/board_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  late AppFlowyBoardTest boardTest;

  setUpAll(() async {
    boardTest = await AppFlowyBoardTest.ensureInitialized();
  });

  group('$BoardBloc', () {
    test('create kanban baord card', () async {
      final context = await boardTest.createTestBoard();
      final boardBloc = BoardBloc(view: context.gridView)
        ..add(const BoardEvent.initial());
      await boardResponseFuture();
      final groupId = boardBloc.state.groupIds.first;

      // the group at index 0 is the 'No status' group;
      assert(boardBloc.groupControllers[groupId]!.group.rows.isEmpty);
      assert(boardBloc.state.groupIds.length == 4);

      boardBloc.add(BoardEvent.createBottomRow(boardBloc.state.groupIds[0]));
      await boardResponseFuture();

      assert(boardBloc.groupControllers[groupId]!.group.rows.length == 1);
    });
  });
}
