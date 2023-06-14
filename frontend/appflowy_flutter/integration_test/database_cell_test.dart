import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
  });
}
