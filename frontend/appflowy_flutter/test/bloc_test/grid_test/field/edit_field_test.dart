import 'package:appflowy/plugins/database/application/field/field_editor_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

Future<FieldEditorBloc> createEditorBloc(AppFlowyGridTest gridTest) async {
  final context = await gridTest.createTestGrid();
  final fieldInfo = context.getSelectOptionField();
  return FieldEditorBloc(
    viewId: context.gridView.id,
    fieldController: context.fieldController,
    fieldInfo: fieldInfo,
    isNew: false,
  );
}

void main() {
  late AppFlowyGridTest gridTest;

  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  test('rename field', () async {
    final editorBloc = await createEditorBloc(gridTest);
    editorBloc.add(const FieldEditorEvent.renameField('Hello world'));

    await gridResponseFuture();
    expect(editorBloc.state.field.name, equals("Hello world"));
  });

  test('switch to text field', () async {
    final editorBloc = await createEditorBloc(gridTest);

    editorBloc.add(const FieldEditorEvent.switchFieldType(FieldType.RichText));
    await gridResponseFuture();

    // The default length of the fields is 3. The length of the fields
    // should not change after switching to other field type
    expect(editorBloc.state.field.fieldType, equals(FieldType.RichText));
  });
}
