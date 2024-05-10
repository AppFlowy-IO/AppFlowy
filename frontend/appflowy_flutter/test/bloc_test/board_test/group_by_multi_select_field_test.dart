import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/setting/group_bloc.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/select_option_cell_editor_bloc.dart';
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
      databaseController: DatabaseController(view: context.gridView),
    )..add(const BoardEvent.initial());
    await boardResponseFuture();
    assert(
      boardBloc.groupControllers.values.length == 1,
      "Expected 1, but receive ${boardBloc.groupControllers.values.length}",
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
    final cellController =
        context.makeCellControllerFromFieldId(multiSelectField.id)
            as SelectOptionCellController;

    final bloc = SelectOptionCellEditorBloc(cellController: cellController);
    await boardResponseFuture();
    bloc.add(const SelectOptionCellEditorEvent.filterOption("A"));
    bloc.add(const SelectOptionCellEditorEvent.createOption());
    await boardResponseFuture();
    bloc.add(const SelectOptionCellEditorEvent.filterOption("B"));
    bloc.add(const SelectOptionCellEditorEvent.createOption());
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
      databaseController: DatabaseController(view: context.gridView),
    )..add(const BoardEvent.initial());
    await boardResponseFuture();
    assert(
      boardBloc.groupControllers.values.length == 3,
      "Expected 3, but receive ${boardBloc.groupControllers.values.length}",
    );
  });
}
