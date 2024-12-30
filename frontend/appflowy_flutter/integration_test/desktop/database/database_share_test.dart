import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('database', () {
    testWidgets('import v0.2.0 database data', (tester) async {
      await tester.openTestDatabase(v020GridFileName);
      // wait the database data is loaded
      await tester.pumpAndSettle(const Duration(microseconds: 500));

      // check the text cell
      final textCells = <String>['A', 'B', 'C', 'D', 'E', '', '', '', '', ''];
      for (final (index, content) in textCells.indexed) {
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.RichText,
          content: content,
        );
      }

      // check the checkbox cell
      final checkboxCells = <bool>[
        true,
        true,
        true,
        true,
        true,
        false,
        false,
        false,
        false,
        false,
      ];
      for (final (index, content) in checkboxCells.indexed) {
        await tester.assertCheckboxCell(
          rowIndex: index,
          isSelected: content,
        );
      }

      // check the number cell
      final numberCells = <String>[
        '-1',
        '-2',
        '0.1',
        '0.2',
        '1',
        '2',
        '10',
        '11',
        '12',
        '',
      ];
      for (final (index, content) in numberCells.indexed) {
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.Number,
          content: content,
        );
      }

      // check the url cell
      final urlCells = <String>[
        'appflowy.io',
        'no url',
        'appflowy.io',
        'https://github.com/AppFlowy-IO/',
        '',
        '',
      ];
      for (final (index, content) in urlCells.indexed) {
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.URL,
          content: content,
        );
      }

      // check the single select cell
      final singleSelectCells = <String>[
        's1',
        's2',
        's3',
        's4',
        's5',
        '',
        '',
        '',
        '',
        '',
      ];
      for (final (index, content) in singleSelectCells.indexed) {
        await tester.assertSingleSelectOption(
          rowIndex: index,
          content: content,
        );
      }

      // check the multi select cell
      final List<List<String>> multiSelectCells = [
        ['m1'],
        ['m1', 'm2'],
        ['m1', 'm2', 'm3'],
        ['m1', 'm2', 'm3'],
        ['m1', 'm2', 'm3', 'm4', 'm5'],
        [],
        [],
        [],
        [],
        [],
      ];
      for (final (index, contents) in multiSelectCells.indexed) {
        tester.assertMultiSelectOption(
          rowIndex: index,
          contents: contents,
        );
      }

      // check the checklist cell
      final List<double?> checklistCells = [
        0.67,
        0.33,
        1.0,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ];
      for (final (index, percent) in checklistCells.indexed) {
        tester.assertChecklistCellInGrid(
          rowIndex: index,
          percent: percent,
        );
      }

      // check the date cell
      final List<String> dateCells = [
        'Jun 01, 2023',
        'Jun 02, 2023',
        'Jun 03, 2023',
        'Jun 04, 2023',
        'Jun 05, 2023',
        'Jun 05, 2023',
        'Jun 16, 2023',
        '',
        '',
        '',
      ];
      for (final (index, content) in dateCells.indexed) {
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.DateTime,
          content: content,
        );
      }
    });
  });
}
