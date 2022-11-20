import 'package:app_flowy/plugins/board/application/board_bloc.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/cell/select_option_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/setting/group_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  late AppFlowyBoardTest boardTest;

  setUpAll(() async {
    boardTest = await AppFlowyBoardTest.ensureInitialized();
  });

  test('group by multi select with no options test', () async {
    final context = await boardTest.createTestBoard();

    // create multi-select field
    await context.createField(FieldType.MultiSelect);
    await boardResponseFuture();
    assert(context.fieldContexts.length == 3);
    final multiSelectField = context.fieldContexts.last.field;

    // set grouped by the new multi-select field"
    final gridGroupBloc = GridGroupBloc(
      viewId: context.gridView.id,
      fieldController: context.fieldController,
    );
    gridGroupBloc.add(GridGroupEvent.setGroupByField(
      multiSelectField.id,
      multiSelectField.fieldType,
    ));
    await boardResponseFuture();

    //assert only have the 'No status' group
    final boardBloc = BoardBloc(view: context.gridView)
      ..add(const BoardEvent.initial());
    await boardResponseFuture();
    assert(boardBloc.groupControllers.values.length == 1,
        "Expected 1, but receive ${boardBloc.groupControllers.values.length}");
    final expectedGroupName = "No ${multiSelectField.name}";
    assert(
        boardBloc.groupControllers.values.first.group.desc == expectedGroupName,
        "Expected $expectedGroupName, but receive ${boardBloc.groupControllers.values.first.group.desc}");
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
        as GridSelectOptionCellController;

    final multiSelectOptionBloc =
        SelectOptionCellEditorBloc(cellController: cellController);
    multiSelectOptionBloc.add(const SelectOptionEditorEvent.initial());
    await boardResponseFuture();
    multiSelectOptionBloc.add(const SelectOptionEditorEvent.newOption("A"));
    await boardResponseFuture();
    multiSelectOptionBloc.add(const SelectOptionEditorEvent.newOption("B"));
    await boardResponseFuture();

    // set grouped by the new multi-select field"
    final gridGroupBloc = GridGroupBloc(
      viewId: context.gridView.id,
      fieldController: context.fieldController,
    );
    gridGroupBloc.add(GridGroupEvent.setGroupByField(
      multiSelectField.id,
      multiSelectField.fieldType,
    ));
    await boardResponseFuture();

    // assert there are only three group
    final boardBloc = BoardBloc(view: context.gridView)
      ..add(const BoardEvent.initial());
    await boardResponseFuture();
    assert(boardBloc.groupControllers.values.length == 3,
        "Expected 3, but receive ${boardBloc.groupControllers.values.length}");

    final groups =
        boardBloc.groupControllers.values.map((e) => e.group).toList();
    assert(groups[0].desc == "No ${multiSelectField.name}");
    assert(groups[1].desc == "B");
    assert(groups[2].desc == "A");
  });
}
