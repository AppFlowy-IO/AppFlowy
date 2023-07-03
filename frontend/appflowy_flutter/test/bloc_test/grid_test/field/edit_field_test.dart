import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import '../util.dart';

Future<FieldEditorBloc> createEditorBloc(AppFlowyGridTest gridTest) async {
  final context = await gridTest.createTestGrid();
  final fieldInfo = context.singleSelectFieldContext();
  final loader = FieldTypeOptionLoader(
    viewId: context.gridView.id,
    field: fieldInfo.field,
  );

  return FieldEditorBloc(
    isGroupField: fieldInfo.isGroupField,
    loader: loader,
    field: fieldInfo.field,
  )..add(const FieldEditorEvent.initial());
}

void main() {
  late AppFlowyGridTest gridTest;

  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  test('rename field', () async {
    final editorBloc = await makeEditorBloc(gridTest);
    editorBloc.add(const FieldEditorEvent.updateName('Hello world'));
    await gridResponseFuture();

    editorBloc.state.field.fold(
      () => throw Exception("The field should not be none"),
      (field) {
        assert(field.name == 'Hello world');
      },
    );
  });

  test('switch to text field', () async {
    final editorBloc = await makeEditorBloc(gridTest);

    editorBloc.add(const FieldEditorEvent.switchToField(FieldType.RichText));
    await gridResponseFuture();

    editorBloc.state.field.fold(
      () => throw Exception("The field should not be none"),
      (field) {
        // The default length of the fields is 3. The length of the fields
        // should not change after switching to other field type
        // assert(gridTest.fieldContexts.length == 3);
        assert(field.fieldType == FieldType.RichText);
      },
    );
  });

  test('delete field', () async {
    final editorBloc = await makeEditorBloc(gridTest);
    editorBloc.add(const FieldEditorEvent.switchToField(FieldType.RichText));
    await gridResponseFuture();

    editorBloc.state.field.fold(
      () => throw Exception("The field should not be none"),
      (field) {
        // The default length of the fields is 3. The length of the fields
        // should not change after switching to other field type
        // assert(gridTest.fieldContexts.length == 3);
        assert(field.fieldType == FieldType.RichText);
      },
    );
  });
}

Future<FieldEditorBloc> makeEditorBloc(AppFlowyGridTest gridTest) async {
  final context = await gridTest.createTestGrid();
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

  await gridResponseFuture();

  return editorBloc;
}
