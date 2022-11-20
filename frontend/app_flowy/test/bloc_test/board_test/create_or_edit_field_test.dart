import 'package:app_flowy/plugins/board/application/board_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/field_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'util.dart';

void main() {
  late AppFlowyBoardTest boardTest;

  setUpAll(() async {
    boardTest = await AppFlowyBoardTest.ensureInitialized();
  });

  group('The grouped field is not changed after editing a field:', () {
    late BoardBloc boardBloc;
    late FieldEditorBloc editorBloc;
    late BoardTestContext context;
    setUpAll(() async {
      context = await boardTest.createTestBoard();
    });

    setUp(() async {
      boardBloc = BoardBloc(view: context.gridView)
        ..add(const BoardEvent.initial());

      final fieldContext = context.singleSelectFieldContext();
      final loader = FieldTypeOptionLoader(
        gridId: context.gridView.id,
        field: fieldContext.field,
      );

      editorBloc = FieldEditorBloc(
        gridId: context.gridView.id,
        fieldName: fieldContext.name,
        isGroupField: fieldContext.isGroupField,
        loader: loader,
      )..add(const FieldEditorEvent.initial());

      await boardResponseFuture();
    });

    blocTest<BoardBloc, BoardState>(
      "initial",
      build: () => boardBloc,
      wait: boardResponseDuration(),
      verify: (bloc) {
        assert(bloc.groupControllers.values.length == 4);
        assert(context.fieldContexts.length == 2);
      },
    );

    blocTest<FieldEditorBloc, FieldEditorState>(
      "edit a field",
      build: () => editorBloc,
      act: (bloc) async {
        editorBloc.add(const FieldEditorEvent.updateName('Hello world'));
      },
      wait: boardResponseDuration(),
      verify: (bloc) {
        bloc.state.field.fold(
          () => throw Exception("The field should not be none"),
          (field) {
            assert(field.name == 'Hello world');
          },
        );
      },
    );

    blocTest<BoardBloc, BoardState>(
      "assert the groups were not changed",
      build: () => boardBloc,
      wait: boardResponseDuration(),
      verify: (bloc) {
        assert(bloc.groupControllers.values.length == 4,
            "Expected 4, but receive ${bloc.groupControllers.values.length}");

        assert(context.fieldContexts.length == 2,
            "Expected 2, but receive ${context.fieldContexts.length}");
      },
    );
  });
  group('The grouped field is not changed after creating a new field:', () {
    late BoardBloc boardBloc;
    late BoardTestContext context;
    setUpAll(() async {
      context = await boardTest.createTestBoard();
    });

    setUp(() async {
      boardBloc = BoardBloc(view: context.gridView)
        ..add(const BoardEvent.initial());
      await boardResponseFuture();
    });

    blocTest<BoardBloc, BoardState>(
      "initial",
      build: () => boardBloc,
      wait: boardResponseDuration(),
      verify: (bloc) {
        assert(bloc.groupControllers.values.length == 4);
        assert(context.fieldContexts.length == 2);
      },
    );

    test('create a field', () async {
      await context.createField(FieldType.Checkbox);
      await boardResponseFuture();
      final checkboxField = context.fieldContexts.last.field;
      assert(checkboxField.fieldType == FieldType.Checkbox);
    });

    blocTest<BoardBloc, BoardState>(
      "assert the groups were not changed",
      build: () => boardBloc,
      wait: boardResponseDuration(),
      verify: (bloc) {
        assert(bloc.groupControllers.values.length == 4,
            "Expected 4, but receive ${bloc.groupControllers.values.length}");

        assert(context.fieldContexts.length == 3,
            "Expected 3, but receive ${context.fieldContexts.length}");
      },
    );
  });
}
