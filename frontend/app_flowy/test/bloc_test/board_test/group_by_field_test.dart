import 'package:app_flowy/plugins/board/application/board_bloc.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/cell/select_option_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/field_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/setting/group_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  late AppFlowyBoardTest boardTest;

  setUpAll(() async {
    boardTest = await AppFlowyBoardTest.ensureInitialized();
  });

  // Group by multi-select with no options
  group('Group by multi-select with no options', () {
    //
    late FieldPB multiSelectField;
    late String expectedGroupName;

    setUpAll(() async {
      await boardTest.context.createTestBoard();
    });

    test('create multi-select field', () async {
      await boardTest.context.createField(FieldType.MultiSelect);
      await boardResponseFuture();

      assert(boardTest.context.fieldContexts.length == 3);
      multiSelectField = boardTest.context.fieldContexts.last.field;
      expectedGroupName = "No ${multiSelectField.name}";
      assert(multiSelectField.fieldType == FieldType.MultiSelect);
    });

    blocTest<GridGroupBloc, GridGroupState>(
      "set grouped by the new multi-select field",
      build: () => GridGroupBloc(
        viewId: boardTest.context.gridView.id,
        fieldController: boardTest.context.fieldController,
      ),
      act: (bloc) async {
        bloc.add(GridGroupEvent.setGroupByField(
          multiSelectField.id,
          multiSelectField.fieldType,
        ));
      },
      wait: boardResponseDuration(),
    );

    blocTest<BoardBloc, BoardState>(
      "assert only have the 'No status' group",
      build: () => BoardBloc(view: boardTest.context.gridView)
        ..add(const BoardEvent.initial()),
      wait: boardResponseDuration(),
      verify: (bloc) {
        assert(bloc.groupControllers.values.length == 1,
            "Expected 1, but receive ${bloc.groupControllers.values.length}");

        assert(
            bloc.groupControllers.values.first.group.desc == expectedGroupName,
            "Expected $expectedGroupName, but receive ${bloc.groupControllers.values.first.group.desc}");
      },
    );
  });

  group('Group by multi-select with two options', () {
    late FieldPB multiSelectField;

    setUpAll(() async {
      await boardTest.context.createTestBoard();
    });

    test('create multi-select field', () async {
      await boardTest.context.createField(FieldType.MultiSelect);
      await boardResponseFuture();

      assert(boardTest.context.fieldContexts.length == 3);
      multiSelectField = boardTest.context.fieldContexts.last.field;
      assert(multiSelectField.fieldType == FieldType.MultiSelect);

      final cellController =
          await boardTest.context.makeCellController(multiSelectField.id)
              as GridSelectOptionCellController;

      final multiSelectOptionBloc =
          SelectOptionCellEditorBloc(cellController: cellController);
      multiSelectOptionBloc.add(const SelectOptionEditorEvent.initial());
      await boardResponseFuture();

      multiSelectOptionBloc.add(const SelectOptionEditorEvent.newOption("A"));
      await boardResponseFuture();

      multiSelectOptionBloc.add(const SelectOptionEditorEvent.newOption("B"));
      await boardResponseFuture();
    });

    blocTest<GridGroupBloc, GridGroupState>(
      "set grouped by multi-select field",
      build: () => GridGroupBloc(
        viewId: boardTest.context.gridView.id,
        fieldController: boardTest.context.fieldController,
      ),
      act: (bloc) async {
        await boardResponseFuture();
        bloc.add(GridGroupEvent.setGroupByField(
          multiSelectField.id,
          multiSelectField.fieldType,
        ));
      },
      wait: boardResponseDuration(),
    );

    blocTest<BoardBloc, BoardState>(
      "check the groups' order",
      build: () => BoardBloc(view: boardTest.context.gridView)
        ..add(const BoardEvent.initial()),
      wait: boardResponseDuration(),
      verify: (bloc) {
        assert(bloc.groupControllers.values.length == 3,
            "Expected 3, but receive ${bloc.groupControllers.values.length}");

        final groups =
            bloc.groupControllers.values.map((e) => e.group).toList();
        assert(groups[0].desc == "No ${multiSelectField.name}");
        assert(groups[1].desc == "B");
        assert(groups[2].desc == "A");
      },
    );
  });

  // Group by checkbox field
  group('Group by checkbox field:', () {
    late BoardBloc boardBloc;
    late FieldPB checkboxField;
    setUpAll(() async {
      await boardTest.context.createTestBoard();
    });

    setUp(() async {
      boardBloc = BoardBloc(view: boardTest.context.gridView)
        ..add(const BoardEvent.initial());
      await boardResponseFuture();
    });

    blocTest<BoardBloc, BoardState>(
      "initial",
      build: () => boardBloc,
      wait: boardResponseDuration(),
      verify: (bloc) {
        assert(bloc.groupControllers.values.length == 4);
        assert(boardTest.context.fieldContexts.length == 2);
      },
    );

    test('create checkbox field', () async {
      await boardTest.context.createField(FieldType.Checkbox);
      await boardResponseFuture();

      assert(boardTest.context.fieldContexts.length == 3);
      checkboxField = boardTest.context.fieldContexts.last.field;
      assert(checkboxField.fieldType == FieldType.Checkbox);
    });

    blocTest<GridGroupBloc, GridGroupState>(
      "set grouped by checkbox field",
      build: () => GridGroupBloc(
        viewId: boardTest.context.gridView.id,
        fieldController: boardTest.context.fieldController,
      ),
      act: (bloc) async {
        bloc.add(GridGroupEvent.setGroupByField(
          checkboxField.id,
          checkboxField.fieldType,
        ));
      },
      wait: boardResponseDuration(),
    );

    blocTest<BoardBloc, BoardState>(
      "check the number of groups is 2",
      build: () => boardBloc,
      wait: boardResponseDuration(),
      verify: (bloc) {
        assert(bloc.groupControllers.values.length == 2);
      },
    );
  });

  // Group with not support grouping field
  group('Group with not support grouping field:', () {
    late FieldEditorBloc editorBloc;
    setUpAll(() async {
      await boardTest.context.createTestBoard();
      final fieldContext = boardTest.context.singleSelectFieldContext();
      editorBloc = boardTest.context.createFieldEditor(
        fieldContext: fieldContext,
      )..add(const FieldEditorEvent.initial());

      await boardResponseFuture();
    });

    blocTest<FieldEditorBloc, FieldEditorState>(
      "switch to text field",
      build: () => editorBloc,
      wait: boardResponseDuration(),
      act: (bloc) async {
        bloc.add(const FieldEditorEvent.switchToField(FieldType.RichText));
      },
      verify: (bloc) {
        bloc.state.field.fold(
          () => throw Exception(),
          (field) => field.fieldType == FieldType.RichText,
        );
      },
    );
    blocTest<BoardBloc, BoardState>(
      'assert the number of groups is 1',
      build: () => BoardBloc(view: boardTest.context.gridView)
        ..add(const BoardEvent.initial()),
      wait: boardResponseDuration(),
      verify: (bloc) {
        assert(bloc.groupControllers.values.length == 1,
            "Expected 1, but receive ${bloc.groupControllers.values.length}");
      },
    );
  });
}
