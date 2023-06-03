import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/board/application/board_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'util.dart';

void main() {
  late AppFlowyBoardTest boardTest;

  setUpAll(() async {
    boardTest = await AppFlowyBoardTest.ensureInitialized();
  });

  test('create build-in kanban board test', () async {
    final context = await boardTest.createTestBoard();
    final boardBloc = BoardBloc(view: context.gridView)
      ..add(const BoardEvent.initial());
    await boardResponseFuture();

    assert(boardBloc.groupControllers.values.length == 4);
    assert(context.fieldContexts.length == 2);
  });

  test('edit kanban board field name test', () async {
    final context = await boardTest.createTestBoard();
    final boardBloc = BoardBloc(view: context.gridView)
      ..add(const BoardEvent.initial());
    await boardResponseFuture();

    final fieldInfo = context.singleSelectFieldContext();
    final loader = FieldTypeOptionLoader(
      viewId: context.gridView.id,
      field: fieldInfo.field,
    );

    final editorBloc = FieldEditorBloc(
      isGroupField: fieldInfo.isGroupField,
      loader: loader,
      field: fieldInfo.field,
    )..add(const FieldEditorEvent.initial());
    await boardResponseFuture();

    editorBloc.add(const FieldEditorEvent.updateName('Hello world'));
    await boardResponseFuture();

    // assert the groups were not changed
    assert(
      boardBloc.groupControllers.values.length == 4,
      "Expected 4, but receive ${boardBloc.groupControllers.values.length}",
    );

    assert(
      context.fieldContexts.length == 2,
      "Expected 2, but receive ${context.fieldContexts.length}",
    );
  });

  test('create a new field in kanban board test', () async {
    final context = await boardTest.createTestBoard();
    final boardBloc = BoardBloc(view: context.gridView)
      ..add(const BoardEvent.initial());
    await boardResponseFuture();

    await context.createField(FieldType.Checkbox);
    await boardResponseFuture();
    final checkboxField = context.fieldContexts.last.field;
    assert(checkboxField.fieldType == FieldType.Checkbox);

    assert(
      boardBloc.groupControllers.values.length == 4,
      "Expected 4, but receive ${boardBloc.groupControllers.values.length}",
    );

    assert(
      context.fieldContexts.length == 3,
      "Expected 3, but receive ${context.fieldContexts.length}",
    );
  });
}
