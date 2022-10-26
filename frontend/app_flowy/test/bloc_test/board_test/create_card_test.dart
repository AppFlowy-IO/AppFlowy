import 'package:app_flowy/plugins/board/application/board_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  late AppFlowyBoardTest boardTest;

  setUpAll(() async {
    boardTest = await AppFlowyBoardTest.ensureInitialized();
  });

  group('$BoardBloc', () {
    late BoardBloc boardBloc;
    late String groupId;

    setUp(() async {
      await boardTest.createTestBoard();
      boardBloc = BoardBloc(view: boardTest.boardView)
        ..add(const BoardEvent.initial());
      await boardResponseFuture();
      groupId = boardBloc.state.groupIds.first;

      // the group at index 0 is the 'No status' group;
      assert(boardBloc.groupControllers[groupId]!.group.rows.isEmpty);
      assert(boardBloc.state.groupIds.length == 4);
    });

    blocTest<BoardBloc, BoardState>(
      "create card",
      build: () => boardBloc,
      act: (bloc) async {
        boardBloc.add(BoardEvent.createBottomRow(boardBloc.state.groupIds[0]));
      },
      wait: boardResponseDuration(),
      verify: (bloc) {
        //

        assert(bloc.groupControllers[groupId]!.group.rows.length == 1);
      },
    );
  });
}
