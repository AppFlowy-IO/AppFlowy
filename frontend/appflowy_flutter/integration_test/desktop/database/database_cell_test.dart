import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('edit grid cell:', () {
    testWidgets('text', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      await tester.editCell(
        rowIndex: 0,
        fieldType: FieldType.RichText,
        input: 'hello world',
      );

      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.RichText,
        content: 'hello world',
      );

      await tester.pumpAndSettle();
    });

    // Make sure the text cells are filled with the right content when there are
    // multiple text cell
    testWidgets('multiple text cells', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent(
        name: 'my grid',
        layout: ViewLayoutPB.Grid,
      );
      await tester.createField(FieldType.RichText, name: 'description');

      await tester.editCell(
        rowIndex: 0,
        fieldType: FieldType.RichText,
        input: 'hello',
      );

      await tester.editCell(
        rowIndex: 0,
        fieldType: FieldType.RichText,
        input: 'world',
        cellIndex: 1,
      );

      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.RichText,
        content: 'hello',
      );

      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.RichText,
        content: 'world',
        cellIndex: 1,
      );

      await tester.pumpAndSettle();
    });

    testWidgets('number', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      const fieldType = FieldType.Number;

      // Create a number field
      await tester.createField(fieldType);

      await tester.editCell(
        rowIndex: 0,
        fieldType: fieldType,
        input: '-1',
      );
      // edit the next cell to force the previous cell at row 0 to lose focus
      await tester.editCell(
        rowIndex: 1,
        fieldType: fieldType,
        input: '0.2',
      );
      // -1 -> -1
      tester.assertCellContent(
        rowIndex: 0,
        fieldType: fieldType,
        content: '-1',
      );

      // edit the next cell to force the previous cell at row 1 to lose focus
      await tester.editCell(
        rowIndex: 2,
        fieldType: fieldType,
        input: '.1',
      );
      // 0.2 -> 0.2
      tester.assertCellContent(
        rowIndex: 1,
        fieldType: fieldType,
        content: '0.2',
      );

      // edit the next cell to force the previous cell at row 2 to lose focus
      await tester.editCell(
        rowIndex: 0,
        fieldType: fieldType,
        input: '',
      );
      // .1 -> 0.1
      tester.assertCellContent(
        rowIndex: 2,
        fieldType: fieldType,
        content: '0.1',
      );

      await tester.pumpAndSettle();
    });

    testWidgets('checkbox', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      await tester.assertCheckboxCell(rowIndex: 0, isSelected: false);
      await tester.tapCheckboxCellInGrid(rowIndex: 0);
      await tester.assertCheckboxCell(rowIndex: 0, isSelected: true);

      await tester.tapCheckboxCellInGrid(rowIndex: 1);
      await tester.tapCheckboxCellInGrid(rowIndex: 2);
      await tester.assertCheckboxCell(rowIndex: 1, isSelected: true);
      await tester.assertCheckboxCell(rowIndex: 2, isSelected: true);

      await tester.pumpAndSettle();
    });

    testWidgets('created time', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      const fieldType = FieldType.CreatedTime;
      // Create a create time field
      // The create time field is not editable
      await tester.createField(fieldType);

      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);

      await tester.findDateEditor(findsNothing);

      await tester.pumpAndSettle();
    });

    testWidgets('last modified time', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      const fieldType = FieldType.LastEditedTime;
      // Create a last time field
      // The last time field is not editable
      await tester.createField(fieldType);

      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);

      await tester.findDateEditor(findsNothing);

      await tester.pumpAndSettle();
    });

    testWidgets('date time', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      const fieldType = FieldType.DateTime;
      await tester.createField(fieldType);

      // Tap the cell to invoke the field editor
      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findDateEditor(findsOneWidget);

      // Toggle include time
      await tester.toggleIncludeTime();

      // Dismiss the cell editor
      await tester.dismissCellEditor();

      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findDateEditor(findsOneWidget);

      // Turn off include time
      await tester.toggleIncludeTime();

      // Select a date
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month, now.day);
      await tester.selectDay(content: now.day);

      await tester.dismissCellEditor();

      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.DateTime,
        content: DateFormat('MMM dd, y').format(expected),
      );

      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);

      // Toggle include time
      // When toggling include time, the time value is from the previous existing date time, not the current time
      await tester.toggleIncludeTime();

      await tester.dismissCellEditor();

      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.DateTime,
        content: DateFormat('MMM dd, y HH:mm').format(expected),
      );

      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findDateEditor(findsOneWidget);

      // Change date format
      await tester.tapChangeDateTimeFormatButton();
      await tester.changeDateFormat();

      await tester.dismissCellEditor();

      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.DateTime,
        content: DateFormat('dd/MM/y HH:mm').format(expected),
      );

      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findDateEditor(findsOneWidget);

      // Change time format
      await tester.tapChangeDateTimeFormatButton();
      await tester.changeTimeFormat();

      await tester.dismissCellEditor();

      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.DateTime,
        content: DateFormat('dd/MM/y hh:mm a').format(expected),
      );

      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findDateEditor(findsOneWidget);

      // Clear the date and time
      await tester.clearDate();

      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.DateTime,
        content: '',
      );

      await tester.pumpAndSettle();
    });

    testWidgets('single select', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      const fieldType = FieldType.SingleSelect;

      // When create a grid, it will create a single select field by default
      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Tap the cell to invoke the selection option editor
      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // Create a new select option
      await tester.createOption(name: 'tag 1');
      await tester.dismissCellEditor();

      // Make sure the option is created and displayed in the cell
      tester.findSelectOptionWithNameInGrid(
        rowIndex: 0,
        name: 'tag 1',
      );

      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // Create another select option
      await tester.createOption(name: 'tag 2');
      await tester.dismissCellEditor();

      tester.findSelectOptionWithNameInGrid(
        rowIndex: 0,
        name: 'tag 2',
      );

      tester.assertNumberOfSelectedOptionsInGrid(
        rowIndex: 0,
        matcher: findsOneWidget,
      );

      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // switch to first option
      await tester.selectOption(name: 'tag 1');
      await tester.dismissCellEditor();

      tester.findSelectOptionWithNameInGrid(
        rowIndex: 0,
        name: 'tag 1',
      );

      tester.assertNumberOfSelectedOptionsInGrid(
        rowIndex: 0,
        matcher: findsOneWidget,
      );

      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // Deselect the currently-selected option
      await tester.selectOption(name: 'tag 1');
      await tester.dismissCellEditor();

      tester.assertNumberOfSelectedOptionsInGrid(
        rowIndex: 0,
        matcher: findsNothing,
      );

      await tester.pumpAndSettle();
    });

    testWidgets('multi select', (tester) async {
      final tags = [
        'tag 1',
        'tag 2',
        'tag 3',
        'tag 4',
      ];

      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      const fieldType = FieldType.MultiSelect;
      await tester.createField(fieldType, name: fieldType.i18n);

      // Tap the cell to invoke the selection option editor
      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // Create a new select option
      await tester.createOption(name: tags.first);
      await tester.dismissCellEditor();

      // Make sure the option is created and displayed in the cell
      tester.findSelectOptionWithNameInGrid(
        rowIndex: 0,
        name: tags.first,
      );

      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // Create some other select options
      await tester.createOption(name: tags[1]);
      await tester.createOption(name: tags[2]);
      await tester.createOption(name: tags[3]);
      await tester.dismissCellEditor();

      for (final tag in tags) {
        tester.findSelectOptionWithNameInGrid(
          rowIndex: 0,
          name: tag,
        );
      }

      tester.assertNumberOfSelectedOptionsInGrid(
        rowIndex: 0,
        matcher: findsNWidgets(4),
      );

      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // Deselect all options
      for (final tag in tags) {
        await tester.selectOption(name: tag);
      }
      await tester.dismissCellEditor();

      tester.assertNumberOfSelectedOptionsInGrid(
        rowIndex: 0,
        matcher: findsNothing,
      );

      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // Select some options
      await tester.selectOption(name: tags[1]);
      await tester.selectOption(name: tags[3]);
      await tester.dismissCellEditor();

      tester.findSelectOptionWithNameInGrid(
        rowIndex: 0,
        name: tags[1],
      );
      tester.findSelectOptionWithNameInGrid(
        rowIndex: 0,
        name: tags[3],
      );

      tester.assertNumberOfSelectedOptionsInGrid(
        rowIndex: 0,
        matcher: findsNWidgets(2),
      );

      await tester.pumpAndSettle();
    });

    testWidgets('checklist', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      const fieldType = FieldType.Checklist;
      await tester.createField(fieldType);

      // assert that there is no progress bar in the grid
      tester.assertChecklistCellInGrid(rowIndex: 0, percent: null);

      // tap on the first checklist cell
      await tester.tapChecklistCellInGrid(rowIndex: 0);

      // assert that the checklist editor is shown
      tester.assertChecklistEditorVisible(visible: true);

      // create a new task with enter
      await tester.createNewChecklistTask(name: "task 1", enter: true);

      // assert that the task is displayed
      tester.assertChecklistTaskInEditor(
        index: 0,
        name: "task 1",
        isChecked: false,
      );

      // update the task's name
      await tester.renameChecklistTask(index: 0, name: "task 11");

      // assert that the task's name is updated
      tester.assertChecklistTaskInEditor(
        index: 0,
        name: "task 11",
        isChecked: false,
      );

      // dismiss new task editor
      await tester.dismissCellEditor();

      // dismiss checklist cell editor
      await tester.dismissCellEditor();

      // assert that progress bar is shown in grid at 0%
      tester.assertChecklistCellInGrid(rowIndex: 0, percent: 0);

      // start editing the first checklist cell again
      await tester.tapChecklistCellInGrid(rowIndex: 0);

      // create another task with the create button
      await tester.createNewChecklistTask(name: "task 2", button: true);

      // assert that the task was inserted
      tester.assertChecklistTaskInEditor(
        index: 1,
        name: "task 2",
        isChecked: false,
      );

      // mark it as complete
      await tester.checkChecklistTask(index: 1);

      // assert that the task was checked in the editor
      tester.assertChecklistTaskInEditor(
        index: 1,
        name: "task 2",
        isChecked: true,
      );

      // dismiss checklist editor
      await tester.dismissCellEditor();
      await tester.dismissCellEditor();

      // assert that progressbar is shown in grid at 50%
      tester.assertChecklistCellInGrid(rowIndex: 0, percent: 0.5);

      // re-open the cell editor
      await tester.tapChecklistCellInGrid(rowIndex: 0);

      // hover over first task and delete it
      await tester.deleteChecklistTask(index: 0);

      // dismiss cell editor
      await tester.dismissCellEditor();

      // assert that progressbar is shown in grid at 100%
      tester.assertChecklistCellInGrid(rowIndex: 0, percent: 1);

      // re-open the cell edior
      await tester.tapChecklistCellInGrid(rowIndex: 0);

      // delete the remaining task
      await tester.deleteChecklistTask(index: 0);

      // dismiss the cell editor
      await tester.dismissCellEditor();

      // check that the progress bar is not viisble
      tester.assertChecklistCellInGrid(rowIndex: 0, percent: null);
    });
  });
}
