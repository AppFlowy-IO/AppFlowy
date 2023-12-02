import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/select_option.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/database_test_op.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid field editor:', () {
    testWidgets('rename existing field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(layout: ViewLayoutPB.Grid);

      // Invoke the field editor
      await tester.tapGridFieldWithName('Name');
      await tester.tapEditPropertyButton();

      await tester.renameField('hello world');
      await tester.dismissFieldEditor();

      await tester.tapGridFieldWithName('hello world');
      await tester.pumpAndSettle();
    });

    testWidgets('update field type of existing field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(layout: ViewLayoutPB.Grid);

      // Invoke the field editor
      await tester.tapGridFieldWithName('Type');
      await tester.tapEditPropertyButton();

      await tester.tapTypeOptionButton();
      await tester.selectFieldType(FieldType.Checkbox);
      await tester.dismissFieldEditor();

      await tester.assertFieldTypeWithFieldName(
        'Type',
        FieldType.Checkbox,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('create a field and rename it', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // create a new grid
      await tester.createNewPageWithName(layout: ViewLayoutPB.Grid);

      // create a field
      await tester.createField(FieldType.Checklist, 'checklist');

      // check the field is created successfully
      await tester.findFieldWithName('checklist');
      await tester.pumpAndSettle();
    });

    testWidgets('delete field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(layout: ViewLayoutPB.Grid);

      // create a field
      await tester.createField(FieldType.Checkbox, 'New field 1');

      // Delete the field
      await tester.tapGridFieldWithName('New field 1');
      await tester.tapDeletePropertyButton();

      // confirm delete
      await tester.tapDialogOkButton();

      await tester.noFieldWithName('New field 1');
      await tester.pumpAndSettle();
    });

    testWidgets('duplicate field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(layout: ViewLayoutPB.Grid);

      // create a field
      await tester.scrollToRight(find.byType(GridPage));
      await tester.tapNewPropertyButton();
      await tester.renameField('New field 1');
      await tester.dismissFieldEditor();

      // duplicate the field
      await tester.tapGridFieldWithName('New field 1');
      await tester.tapDuplicatePropertyButton();

      await tester.findFieldWithName('New field 1 (copy)');
      await tester.pumpAndSettle();
    });

    testWidgets('insert field on either side of a field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(layout: ViewLayoutPB.Grid);

      await tester.scrollToRight(find.byType(GridPage));

      // insert new field to the right
      await tester.tapGridFieldWithName('Type');
      await tester.tapInsertFieldButton(left: false, name: 'Right');
      await tester.dismissFieldEditor();
      await tester.findFieldWithName('Right');

      // insert new field to the right
      await tester.tapGridFieldWithName('Type');
      await tester.tapInsertFieldButton(left: true, name: "Left");
      await tester.dismissFieldEditor();
      await tester.findFieldWithName('Left');

      await tester.pumpAndSettle();
    });

    testWidgets('create checklist field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(layout: ViewLayoutPB.Grid);

      await tester.scrollToRight(find.byType(GridPage));
      await tester.tapNewPropertyButton();

      // Open the type option menu
      await tester.tapTypeOptionButton();

      await tester.selectFieldType(FieldType.Checklist);

      // After update the field type, the cells should be updated
      await tester.findCellByFieldType(FieldType.Checklist);

      await tester.pumpAndSettle();
    });

    testWidgets('create list of fields', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(layout: ViewLayoutPB.Grid);

      for (final fieldType in [
        FieldType.Checklist,
        FieldType.DateTime,
        FieldType.Number,
        FieldType.URL,
        FieldType.MultiSelect,
        FieldType.LastEditedTime,
        FieldType.CreatedTime,
        FieldType.Checkbox,
      ]) {
        await tester.scrollToRight(find.byType(GridPage));
        await tester.tapNewPropertyButton();
        await tester.renameField(fieldType.name);

        // Open the type option menu
        await tester.tapTypeOptionButton();

        await tester.selectFieldType(fieldType);
        await tester.dismissFieldEditor();

        // After update the field type, the cells should be updated
        await tester.findCellByFieldType(fieldType);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('add option', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(
        layout: ViewLayoutPB.Grid,
      );

      // Invoke the field editor
      await tester.tapGridFieldWithName('Type');
      await tester.tapEditPropertyButton();

      // tap 'add option' button
      await tester.tapAddSelectOptionButton();
      const text = 'Hello AppFlowy';
      final inputField = find.descendant(
        of: find.byType(CreateOptionTextField),
        matching: find.byType(TextField),
      );
      await tester.enterText(inputField, text);
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // check the result
      tester.expectToSeeText(text);
    });
  });
}
