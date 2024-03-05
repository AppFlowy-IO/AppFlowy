import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/type_option/select/select_option.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid field editor:', () {
    testWidgets('rename existing field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Invoke the field editor
      await tester.tapGridFieldWithName('Name');
      await tester.tapEditFieldButton();

      await tester.renameField('hello world');
      await tester.dismissFieldEditor();

      await tester.tapGridFieldWithName('hello world');
      await tester.pumpAndSettle();
    });

    testWidgets('update field type of existing field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Invoke the field editor
      await tester.changeFieldTypeOfFieldWithName('Type', FieldType.Checkbox);

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
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // create a field
      await tester.createField(FieldType.Checklist, 'checklist');

      // check the field is created successfully
      tester.findFieldWithName('checklist');
      await tester.pumpAndSettle();
    });

    testWidgets('delete field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // create a field
      await tester.createField(FieldType.Checkbox, 'New field 1');

      // Delete the field
      await tester.tapGridFieldWithName('New field 1');
      await tester.tapDeletePropertyButton();

      // confirm delete
      await tester.tapDialogOkButton();

      tester.noFieldWithName('New field 1');
      await tester.pumpAndSettle();
    });

    testWidgets('duplicate field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // create a field
      await tester.scrollToRight(find.byType(GridPage));
      await tester.tapNewPropertyButton();
      await tester.renameField('New field 1');
      await tester.dismissFieldEditor();

      // duplicate the field
      await tester.tapGridFieldWithName('New field 1');
      await tester.tapDuplicatePropertyButton();

      tester.findFieldWithName('New field 1 (copy)');
      await tester.pumpAndSettle();
    });

    testWidgets('insert field on either side of a field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      await tester.scrollToRight(find.byType(GridPage));

      // insert new field to the right
      await tester.tapGridFieldWithName('Type');
      await tester.tapInsertFieldButton(left: false, name: 'Right');
      await tester.dismissFieldEditor();
      tester.findFieldWithName('Right');

      // insert new field to the right
      await tester.tapGridFieldWithName('Type');
      await tester.tapInsertFieldButton(left: true, name: "Left");
      await tester.dismissFieldEditor();
      tester.findFieldWithName('Left');

      await tester.pumpAndSettle();
    });

    testWidgets('create checklist field', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      await tester.scrollToRight(find.byType(GridPage));
      await tester.tapNewPropertyButton();

      // Open the type option menu
      await tester.tapSwitchFieldTypeButton();

      await tester.selectFieldType(FieldType.Checklist);

      // After update the field type, the cells should be updated
      await tester.findCellByFieldType(FieldType.Checklist);

      await tester.pumpAndSettle();
    });

    testWidgets('create list of fields', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

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
        await tester.tapSwitchFieldTypeButton();

        await tester.selectFieldType(fieldType);
        await tester.dismissFieldEditor();

        // After update the field type, the cells should be updated
        await tester.findCellByFieldType(fieldType);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('field types with empty type option editor', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      for (final fieldType in [
        FieldType.RichText,
        FieldType.Checkbox,
        FieldType.Checklist,
        FieldType.URL,
      ]) {
        // create the field
        await tester.scrollToRight(find.byType(GridPage));
        await tester.tapNewPropertyButton();
        await tester.renameField(fieldType.i18n);

        // change field type
        await tester.tapSwitchFieldTypeButton();
        await tester.selectFieldType(fieldType);
        await tester.dismissFieldEditor();

        // open the field editor
        await tester.tapGridFieldWithName(fieldType.i18n);
        await tester.tapEditFieldButton();

        // check type option editor is empty
        tester.expectEmptyTypeOptionEditor();
        await tester.dismissFieldEditor();
      }
    });

    testWidgets('number field type option', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      await tester.scrollToRight(find.byType(GridPage));

      // create a number field
      await tester.tapNewPropertyButton();
      await tester.renameField("Number");
      await tester.tapSwitchFieldTypeButton();
      await tester.selectFieldType(FieldType.Number);
      await tester.dismissFieldEditor();

      // enter some data into the first number cell
      await tester.editCell(
        rowIndex: 0,
        fieldType: FieldType.Number,
        input: '123',
      );
      // edit the next cell to force the previous cell at row 0 to lose focus
      await tester.editCell(
        rowIndex: 1,
        fieldType: FieldType.Number,
        input: '0.2',
      );
      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.Number,
        content: '123',
      );

      // open editor and change number format
      await tester.tapGridFieldWithName('Number');
      await tester.tapEditFieldButton();
      await tester.changeNumberFieldFormat();
      await tester.dismissFieldEditor();

      // assert number format has been changed
      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.Number,
        content: '\$123',
      );
    });

    testWidgets('add option', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(
        layout: ViewLayoutPB.Grid,
      );

      // invoke the field editor
      await tester.tapGridFieldWithName('Type');
      await tester.tapEditFieldButton();

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
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // check the result
      tester.expectToSeeText(text);
    });

    testWidgets('date time field type options', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      await tester.scrollToRight(find.byType(GridPage));

      // create a date field
      await tester.tapNewPropertyButton();
      await tester.renameField(FieldType.DateTime.i18n);
      await tester.tapSwitchFieldTypeButton();
      await tester.selectFieldType(FieldType.DateTime);
      await tester.dismissFieldEditor();

      // edit the first date cell
      await tester.tapCellInGrid(rowIndex: 0, fieldType: FieldType.DateTime);
      await tester.toggleIncludeTime();
      final now = DateTime.now();
      await tester.selectDay(content: now.day);

      await tester.dismissCellEditor();

      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.DateTime,
        content: DateFormat('MMM dd, y HH:mm').format(now),
      );

      // open editor and change date & time format
      await tester.tapGridFieldWithName(FieldType.DateTime.i18n);
      await tester.tapEditFieldButton();
      await tester.changeDateFormat();
      await tester.changeTimeFormat();
      await tester.dismissFieldEditor();

      // assert date format has been changed
      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.DateTime,
        content: DateFormat('dd/MM/y hh:mm a').format(now),
      );
    });

    testWidgets('last modified and created at field type options',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      final created = DateTime.now();

      // create a created at field
      await tester.tapNewPropertyButton();
      await tester.renameField(FieldType.CreatedTime.i18n);
      await tester.tapSwitchFieldTypeButton();
      await tester.selectFieldType(FieldType.CreatedTime);
      await tester.dismissFieldEditor();

      // create a last modified field
      await tester.tapNewPropertyButton();
      await tester.renameField(FieldType.LastEditedTime.i18n);
      await tester.tapSwitchFieldTypeButton();
      await tester.selectFieldType(FieldType.LastEditedTime);
      await tester.dismissFieldEditor();

      final modified = DateTime.now();

      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.CreatedTime,
        content: DateFormat('MMM dd, y HH:mm').format(created),
      );
      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.LastEditedTime,
        content: DateFormat('MMM dd, y HH:mm').format(modified),
      );

      // open field editor and change date & time format
      await tester.tapGridFieldWithName(FieldType.LastEditedTime.i18n);
      await tester.tapEditFieldButton();
      await tester.changeDateFormat();
      await tester.changeTimeFormat();
      await tester.dismissFieldEditor();

      // open field editor and change date & time format
      await tester.tapGridFieldWithName(FieldType.CreatedTime.i18n);
      await tester.tapEditFieldButton();
      await tester.changeDateFormat();
      await tester.changeTimeFormat();
      await tester.dismissFieldEditor();

      // assert format has been changed
      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.CreatedTime,
        content: DateFormat('dd/MM/y hh:mm a').format(created),
      );
      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.LastEditedTime,
        content: DateFormat('dd/MM/y hh:mm a').format(modified),
      );
    });
  });
}
