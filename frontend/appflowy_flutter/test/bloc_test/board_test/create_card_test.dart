import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/protobuf.dart';

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
      orElse: () => const [],
      ready: (value) => value.groupIds,
    );
    String lastGroupId = groupIds.last;

    // the group at index 3 is the 'No status' group;
    assert(boardBloc.groupControllers[lastGroupId]!.group.rows.isEmpty);
    assert(
      groupIds.length == 4,
      'but receive ${groupIds.length}',
    );

    boardBloc.add(
      BoardEvent.createRow(
        groupIds[3],
        OrderObjectPositionTypePB.End,
        null,
        null,
      ),
    );
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

  test('create kanban baord card with url', () async {
    final context = await boardTest.createTestBoard();
    final databaseController = DatabaseController(view: context.gridView);
    final boardBloc = BoardBloc(
      databaseController: databaseController,
    )..add(const BoardEvent.initial());
    await boardResponseFuture();

    await context.createField(FieldType.URL);
    await boardResponseFuture();
    final urlField = context.fieldContexts.last.field;
    assert(urlField.fieldType == FieldType.URL);

    var boardSettings = databaseController.databaseLayoutSetting!.board;
    boardSettings.freeze();
    await databaseController.updateLayoutSetting(
      boardLayoutSetting: boardSettings
          .rebuild((message) => message.urlFieldToFillId = urlField.id),
    );
    await boardResponseFuture();
    assert(
      databaseController.databaseLayoutSetting!.board.urlFieldToFillId ==
          urlField.id,
    );

    final groupIds = boardBloc.state.maybeMap(
      orElse: () => const [],
      ready: (value) => value.groupIds,
    );
    final groupID = groupIds[3];
    const url = "https://appflowy.io/";
    boardBloc.add(
      BoardEvent.createRow(
        groupID,
        OrderObjectPositionTypePB.End,
        "Test",
        null,
        url: url,
      ),
    );
    await boardResponseFuture();

    URLCellController urlCellController =
        context.makeCellControllerFromFieldId(urlField.id) as URLCellController;
    urlCellController.getCellData();
    await boardResponseFuture();
    assert(
      urlCellController.getCellData()?.content == url,
      'but receive ${urlCellController.getCellData()?.content}',
    );

    // Don't fill url if the row title is null
    boardBloc.add(
      BoardEvent.createRow(
        groupID,
        OrderObjectPositionTypePB.End,
        null,
        null,
        url: url,
      ),
    );
    await boardResponseFuture();

    urlCellController =
        context.makeCellControllerFromFieldId(urlField.id) as URLCellController;
    urlCellController.getCellData();
    await boardResponseFuture();
    assert(
      urlCellController.getCellData() == null,
      'but receive ${urlCellController.getCellData()}',
    );

    // Don't fill url if its set to none in board settings
    boardSettings = databaseController.databaseLayoutSetting!.board;
    boardSettings.freeze();
    await databaseController.updateLayoutSetting(
      boardLayoutSetting: boardSettings
          .rebuild((message) => message.clearOneOfUrlFieldToFillId()),
    );
    await boardResponseFuture();
    assert(
      databaseController.databaseLayoutSetting!.board.urlFieldToFillId == "",
    );
    boardBloc.add(
      BoardEvent.createRow(
        groupID,
        OrderObjectPositionTypePB.End,
        "Another test",
        null,
        url: url,
      ),
    );
    await boardResponseFuture();

    urlCellController =
        context.makeCellControllerFromFieldId(urlField.id) as URLCellController;
    urlCellController.getCellData();
    await boardResponseFuture();
    assert(
      urlCellController.getCellData() == null,
      'but receive ${urlCellController.getCellData()}',
    );
  });
}
