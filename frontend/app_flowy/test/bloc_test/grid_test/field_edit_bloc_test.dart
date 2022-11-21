import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'util.dart';

Future<FieldEditorBloc> createEditorBloc(AppFlowyGridTest gridTest) async {
  final context = await gridTest.createTestGrid();
  final fieldInfo = context.singleSelectFieldContext();
  final loader = FieldTypeOptionLoader(
    gridId: context.gridView.id,
    field: fieldInfo.field,
  );

  return FieldEditorBloc(
    gridId: context.gridView.id,
    fieldName: fieldInfo.name,
    isGroupField: fieldInfo.isGroupField,
    loader: loader,
  )..add(const FieldEditorEvent.initial());
}

void main() {
  late AppFlowyGridTest gridTest;

  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('$FieldEditorBloc', () {
    late FieldEditorBloc editorBloc;

    setUp(() async {
      final context = await gridTest.createTestGrid();
      final fieldInfo = context.singleSelectFieldContext();
      final loader = FieldTypeOptionLoader(
        gridId: context.gridView.id,
        field: fieldInfo.field,
      );

      editorBloc = FieldEditorBloc(
        gridId: context.gridView.id,
        fieldName: fieldInfo.name,
        isGroupField: fieldInfo.isGroupField,
        loader: loader,
      )..add(const FieldEditorEvent.initial());

      await gridResponseFuture();
    });

    blocTest<FieldEditorBloc, FieldEditorState>(
      "rename field",
      build: () => editorBloc,
      act: (bloc) async {
        editorBloc.add(const FieldEditorEvent.updateName('Hello world'));
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        bloc.state.field.fold(
          () => throw Exception("The field should not be none"),
          (field) {
            assert(field.name == 'Hello world');
          },
        );
      },
    );

    blocTest<FieldEditorBloc, FieldEditorState>(
      "switch to text field",
      build: () => editorBloc,
      act: (bloc) async {
        editorBloc
            .add(const FieldEditorEvent.switchToField(FieldType.RichText));
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        bloc.state.field.fold(
          () => throw Exception("The field should not be none"),
          (field) {
            // The default length of the fields is 3. The length of the fields
            // should not change after switching to other field type
            // assert(gridTest.fieldContexts.length == 3);
            assert(field.fieldType == FieldType.RichText);
          },
        );
      },
    );

    blocTest<FieldEditorBloc, FieldEditorState>(
      "delete field",
      build: () => editorBloc,
      act: (bloc) async {
        editorBloc.add(const FieldEditorEvent.deleteField());
      },
      wait: gridResponseDuration(),
      verify: (bloc) {
        // assert(gridTest.fieldContexts.length == 2);
      },
    );
  });
}
