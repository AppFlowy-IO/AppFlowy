import 'package:app_flowy/plugins/board/application/board_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/field_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/setting/group_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pbserver.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  late AppFlowyBoardTest boardTest;

  setUpAll(() async {
    boardTest = await AppFlowyBoardTest.ensureInitialized();
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
        await bloc.dataController.switchToField(FieldType.RichText);
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
      await boardTest.context.createFieldFromType(FieldType.Checkbox);
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
}
