import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import '../util.dart';

Future<FieldEditorBloc> createEditorBloc(AppFlowyGridTest gridTest) async {
  final context = await gridTest.createTestGrid();
  final field = context.singleSelectFieldContext();

  return FieldEditorBloc(
    isGroupField: field.isGroupField,
    viewId: context.gridView.id,
  )..add(FieldEditorEvent.initial(field));
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

    final field = editorBloc.state.field;
    assert(field != null && field.name == "Hello world");
  });

  test('switch to text field', () async {
    final editorBloc = await makeEditorBloc(gridTest);

    editorBloc.add(const FieldEditorEvent.switchToField(FieldType.RichText));
    await gridResponseFuture();

    final field = editorBloc.state.field;
    assert(field != null && field.fieldType == FieldType.RichText);
  });

  test('delete field', () async {
    final editorBloc = await makeEditorBloc(gridTest);
    editorBloc.add(const FieldEditorEvent.deleteField());
    await gridResponseFuture();

    final field = editorBloc.state.field;
    assert(field != null && field.fieldType == FieldType.RichText);
  });
}

Future<FieldEditorBloc> makeEditorBloc(AppFlowyGridTest gridTest) async {
  final context = await gridTest.createTestGrid();
  final field = context.singleSelectFieldContext();

  final editorBloc = FieldEditorBloc(
    isGroupField: field.isGroupField,
    viewId: context.gridView.id,
  )..add(FieldEditorEvent.initial(field));

  await gridResponseFuture();

  return editorBloc;
}
