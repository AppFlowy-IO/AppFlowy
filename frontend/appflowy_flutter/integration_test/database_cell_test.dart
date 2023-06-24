import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

import 'util/database_test_op.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid cell', () {
    const location = 'appflowy';

    setUp(() async {
      await TestFolder.cleanTestLocation(location);
      await TestFolder.setTestLocation(location);
    });

    tearDown(() async {
      await TestFolder.cleanTestLocation(location);
    });

    tearDownAll(() async {
      await TestFolder.cleanTestLocation(null);
    });

    testWidgets('edit text cell', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      await tester.editCell(
        rowIndex: 0,
        fieldType: FieldType.RichText,
        input: 'hello world',
      );

      await tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.RichText,
        content: 'hello world',
      );

      await tester.pumpAndSettle();
    });

    // Makesure the text cells are filled with the right content when there are
    // multiple text cell
    testWidgets('edit multiple text cells', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();
      await tester.createNewPageWithName(ViewLayoutPB.Grid, 'my grid');
      await tester.createField(FieldType.RichText, 'description');

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

      await tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.RichText,
        content: 'hello',
        cellIndex: 0,
      );

      await tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.RichText,
        content: 'world',
        cellIndex: 1,
      );

      await tester.pumpAndSettle();
    });

    testWidgets('edit number cell', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      const fieldType = FieldType.Number;

      // Create a number field
      await tester.createField(fieldType, fieldType.name);

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
      await tester.assertCellContent(
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
      await tester.assertCellContent(
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
      await tester.assertCellContent(
        rowIndex: 2,
        fieldType: fieldType,
        content: '0.1',
      );

      await tester.pumpAndSettle();
    });

    testWidgets('edit checkbox cell', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      await tester.assertCheckboxCell(rowIndex: 0, isSelected: false);
      await tester.tapCheckboxCellInGrid(rowIndex: 0);
      await tester.assertCheckboxCell(rowIndex: 0, isSelected: true);

      await tester.tapCheckboxCellInGrid(rowIndex: 1);
      await tester.tapCheckboxCellInGrid(rowIndex: 2);
      await tester.assertCheckboxCell(rowIndex: 1, isSelected: true);
      await tester.assertCheckboxCell(rowIndex: 2, isSelected: true);

      await tester.pumpAndSettle();
    });

    testWidgets('edit create time cell', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      const fieldType = FieldType.CreatedTime;
      // Create a create time field
      // The create time field is not editable
      await tester.createField(fieldType, fieldType.name);

      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);

      await tester.findDateEditor(findsNothing);

      await tester.pumpAndSettle();
    });

    testWidgets('edit last time cell', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      const fieldType = FieldType.LastEditedTime;
      // Create a last time field
      // The last time field is not editable
      await tester.createField(fieldType, fieldType.name);

      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);

      await tester.findDateEditor(findsNothing);

      await tester.pumpAndSettle();
    });

    testWidgets('edit time cell', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      const fieldType = FieldType.DateTime;
      await tester.createField(fieldType, fieldType.name);

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
      final today = DateTime.now();
      await tester.selectDay(content: today.day);

      await tester.dismissCellEditor();

      await tester.assertDateCellInGrid(
        rowIndex: 0,
        fieldType: fieldType,
        content: DateFormat('MMM d, y').format(today),
      );

      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findDateEditor(findsOneWidget);

      // Toggle include time
      final now = DateTime.now();
      await tester.toggleIncludeTime();

      await tester.dismissCellEditor();

      await tester.assertDateCellInGrid(
        rowIndex: 0,
        fieldType: fieldType,
        content: DateFormat('MMM d, y HH:mm').format(now),
      );

      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findDateEditor(findsOneWidget);

      // Change date format
      await tester.changeDateFormat();

      await tester.dismissCellEditor();

      await tester.assertDateCellInGrid(
        rowIndex: 0,
        fieldType: fieldType,
        content: DateFormat('dd/MM/y HH:mm').format(now),
      );

      await tester.tapCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findDateEditor(findsOneWidget);

      // Change time format
      await tester.changeTimeFormat();

      await tester.dismissCellEditor();

      await tester.assertDateCellInGrid(
        rowIndex: 0,
        fieldType: fieldType,
        content: DateFormat('dd/MM/y hh:mm a').format(now),
      );

      await tester.pumpAndSettle();
    });

    testWidgets('edit single select cell', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      const fieldType = FieldType.SingleSelect;
      await tester.tapAddButton();
      // When create a grid, it will create a single select field by default
      await tester.tapCreateGridButton();

      // Tap the cell to invoke the selection option editor
      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // Create a new select option
      await tester.createOption(name: 'tag 1');
      await tester.dismissCellEditor();

      // Make sure the option is created and displayed in the cell
      await tester.findSelectOptionWithNameInGrid(
        rowIndex: 0,
        name: 'tag 1',
      );

      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // Create another select option
      await tester.createOption(name: 'tag 2');
      await tester.dismissCellEditor();

      await tester.findSelectOptionWithNameInGrid(
        rowIndex: 0,
        name: 'tag 2',
      );

      await tester.assertNumberOfSelectedOptionsInGrid(
        rowIndex: 0,
        matcher: findsOneWidget,
      );

      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // switch to first option
      await tester.selectOption(name: 'tag 1');
      await tester.dismissCellEditor();

      await tester.findSelectOptionWithNameInGrid(
        rowIndex: 0,
        name: 'tag 1',
      );

      await tester.assertNumberOfSelectedOptionsInGrid(
        rowIndex: 0,
        matcher: findsOneWidget,
      );

      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // Deselect the currently-selected option
      await tester.selectOption(name: 'tag 1');
      await tester.dismissCellEditor();

      await tester.assertNumberOfSelectedOptionsInGrid(
        rowIndex: 0,
        matcher: findsNothing,
      );

      await tester.pumpAndSettle();
    });

    testWidgets('edit multi select cell', (tester) async {
      final tags = [
        'tag 1',
        'tag 2',
        'tag 3',
        'tag 4',
      ];

      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      const fieldType = FieldType.MultiSelect;
      await tester.createField(fieldType, fieldType.name);

      // Tap the cell to invoke the selection option editor
      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // Create a new select option
      await tester.createOption(name: tags.first);
      await tester.dismissCellEditor();

      // Make sure the option is created and displayed in the cell
      await tester.findSelectOptionWithNameInGrid(
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
        await tester.findSelectOptionWithNameInGrid(
          rowIndex: 0,
          name: tag,
        );
      }

      await tester.assertNumberOfSelectedOptionsInGrid(
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

      await tester.assertNumberOfSelectedOptionsInGrid(
        rowIndex: 0,
        matcher: findsNothing,
      );

      await tester.tapSelectOptionCellInGrid(rowIndex: 0, fieldType: fieldType);
      await tester.findSelectOptionEditor(findsOneWidget);

      // Select some options
      await tester.selectOption(name: tags[1]);
      await tester.selectOption(name: tags[3]);
      await tester.dismissCellEditor();

      await tester.findSelectOptionWithNameInGrid(
        rowIndex: 0,
        name: tags[1],
      );
      await tester.findSelectOptionWithNameInGrid(
        rowIndex: 0,
        name: tags[3],
      );

      await tester.assertNumberOfSelectedOptionsInGrid(
        rowIndex: 0,
        matcher: findsNWidgets(2),
      );

      await tester.pumpAndSettle();
    });
  });
}
