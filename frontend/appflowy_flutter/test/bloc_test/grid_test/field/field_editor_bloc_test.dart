import 'package:appflowy/plugins/database/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanoid/nanoid.dart';

import '../util.dart';

void main() {
  late AppFlowyGridTest gridTest;

  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('field editor bloc:', () {
    late GridTestContext context;
    late FieldEditorBloc editorBloc;

    setUp(() async {
      context = await gridTest.makeDefaultTestGrid();
      final fieldInfo = context.fieldController.fieldInfos
          .firstWhere((field) => field.fieldType == FieldType.SingleSelect);
      editorBloc = FieldEditorBloc(
        viewId: context.view.id,
        fieldController: context.fieldController,
        fieldInfo: fieldInfo,
        isNew: false,
      );
    });

    test('rename field', () async {
      expect(editorBloc.state.field.name, equals("Type"));

      editorBloc.add(const FieldEditorEvent.renameField('Hello world'));

      await gridResponseFuture();
      expect(editorBloc.state.field.name, equals("Hello world"));
    });

    test('edit icon', () async {
      expect(editorBloc.state.field.icon, equals(""));

      editorBloc.add(const FieldEditorEvent.updateIcon('emoji/smiley-face'));

      await gridResponseFuture();
      expect(editorBloc.state.field.icon, equals("emoji/smiley-face"));

      editorBloc.add(const FieldEditorEvent.updateIcon(""));

      await gridResponseFuture();
      expect(editorBloc.state.field.icon, equals(""));
    });

    test('switch to text field', () async {
      expect(editorBloc.state.field.fieldType, equals(FieldType.SingleSelect));

      editorBloc.add(
        const FieldEditorEvent.switchFieldType(FieldType.RichText),
      );
      await gridResponseFuture();

      expect(editorBloc.state.field.fieldType, equals(FieldType.RichText));
    });

    test('update field type option', () async {
      final selectOption = SelectOptionPB()
        ..id = nanoid(4)
        ..color = SelectOptionColorPB.Lime
        ..name = "New option";
      final typeOptionData = SingleSelectTypeOptionPB()
        ..options.addAll([selectOption]);

      editorBloc.add(
        FieldEditorEvent.updateTypeOption(typeOptionData.writeToBuffer()),
      );
      await gridResponseFuture();

      final actual = SingleSelectTypeOptionDataParser()
          .fromBuffer(editorBloc.state.field.field.typeOptionData);

      expect(actual, equals(typeOptionData));
    });

    test('update visibility', () async {
      expect(
        editorBloc.state.field.visibility,
        equals(FieldVisibility.AlwaysShown),
      );

      editorBloc.add(const FieldEditorEvent.toggleFieldVisibility());
      await gridResponseFuture();

      expect(
        editorBloc.state.field.visibility,
        equals(FieldVisibility.AlwaysHidden),
      );
    });

    test('update wrap cell', () async {
      expect(
        editorBloc.state.field.wrapCellContent,
        equals(true),
      );

      editorBloc.add(const FieldEditorEvent.toggleWrapCellContent());
      await gridResponseFuture();

      expect(
        editorBloc.state.field.wrapCellContent,
        equals(false),
      );
    });

    test('insert left and right', () async {
      expect(
        context.fieldController.fieldInfos.length,
        equals(3),
      );

      editorBloc.add(const FieldEditorEvent.insertLeft());
      await gridResponseFuture();
      editorBloc.add(const FieldEditorEvent.insertRight());
      await gridResponseFuture();

      expect(
        context.fieldController.fieldInfos.length,
        equals(5),
      );
    });
  });
}
