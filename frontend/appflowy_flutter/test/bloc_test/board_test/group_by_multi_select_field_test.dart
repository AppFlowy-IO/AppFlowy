import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/setting/group_bloc.dart';
import 'package:appflowy/plugins/database_view/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/select_option_editor_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  late AppFlowyBoardTest boardTest;

  setUpAll(() async {
    boardTest = await AppFlowyBoardTest.ensureInitialized();
  });

  test('no status group name test', () async {
    final context = await boardTest.createTestBoard();

    // create multi-select field
    await context.createField(FieldType.MultiSelect);
    await boardResponseFuture();
    assert(context.fieldContexts.length == 3);
    final multiSelectField = context.fieldContexts.last.field;

    // set grouped by the new multi-select field"
    final gridGroupBloc = DatabaseGroupBloc(
      viewId: context.gridView.id,
      databaseController: context.databaseController,
    )..add(const DatabaseGroupEvent.initial());
    await boardResponseFuture();

    gridGroupBloc.add(
      DatabaseGroupEvent.setGroupByField(
        multiSelectField.id,
        multiSelectField.fieldType,
      ),
    );
    await boardResponseFuture();

    // assert only have the 'No status' group
    final boardBloc = BoardBloc(
      view: context.gridView,
      databaseController: DatabaseController(view: context.gridView),
    )..add(const BoardEvent.initial());
    await boardResponseFuture();
    assert(
      boardBloc.groupControllers.values.length == 1,
      "Expected 1, but receive ${boardBloc.groupControllers.values.length}",
    );
    final expectedGroupName = "No ${multiSelectField.name}";
    assert(
      boardBloc.groupControllers.values.first.group.groupName ==
          expectedGroupName,
      "Expected $expectedGroupName, but receive ${boardBloc.groupControllers.values.first.group.groupName}",
    );
  });

  test('group by multi select with no options test', () async {
    final context = await boardTest.createTestBoard();

    // create multi-select field
    await context.createField(FieldType.MultiSelect);
    await boardResponseFuture();
    assert(context.fieldContexts.length == 3);
    final multiSelectField = context.fieldContexts.last.field;

    // Create options
    final cellController = await context.makeCellController(multiSelectField.id)
        as SelectOptionCellController;

    final multiSelectOptionBloc =
        SelectOptionCellEditorBloc(cellController: cellController);
    multiSelectOptionBloc.add(const SelectOptionEditorEvent.initial());
    await boardResponseFuture();
    multiSelectOptionBloc.add(const SelectOptionEditorEvent.newOption("A"));
    await boardResponseFuture();
    multiSelectOptionBloc.add(const SelectOptionEditorEvent.newOption("B"));
    await boardResponseFuture();

    // set grouped by the new multi-select field"
    final gridGroupBloc = DatabaseGroupBloc(
      viewId: context.gridView.id,
      databaseController: context.databaseController,
    )..add(const DatabaseGroupEvent.initial());
    await boardResponseFuture();

    gridGroupBloc.add(
      DatabaseGroupEvent.setGroupByField(
        multiSelectField.id,
        multiSelectField.fieldType,
      ),
    );
    await boardResponseFuture();

    // assert there are only three group
    final boardBloc = BoardBloc(
      view: context.gridView,
      databaseController: DatabaseController(view: context.gridView),
    )..add(const BoardEvent.initial());
    await boardResponseFuture();
    assert(
      boardBloc.groupControllers.values.length == 3,
      "Expected 3, but receive ${boardBloc.groupControllers.values.length}",
    );

    final groups =
        boardBloc.groupControllers.values.map((e) => e.group).toList();
    assert(groups[0].groupName == "B");
    assert(groups[1].groupName == "A");
    assert(groups[2].groupName == "No ${multiSelectField.name}");
  });
}
