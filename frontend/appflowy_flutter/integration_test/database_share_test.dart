import 'dart:io';

import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/database_test_op.dart';
import 'util/mock/mock_file_picker.dart';
import 'util/util.dart';
import 'package:path/path.dart' as p;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('database', () {
    const location = 'import_files';
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

    testWidgets('import v0.2.0 database data', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // expect to see a readme page
      tester.expectToSeePageName(readme);

      await tester.tapAddButton();
      await tester.tapImportButton();

      final testFileNames = ['v020.afdb'];
      final fileLocation = await tester.currentFileLocation();
      for (final fileName in testFileNames) {
        final str = await rootBundle.loadString(
          p.join(
            'assets/test/workspaces/database',
            fileName,
          ),
        );
        File(p.join(fileLocation, fileName)).writeAsStringSync(str);
      }
      // mock get files
      await mockPickFilePaths(testFileNames, name: location);
      await tester.tapDatabaseRawDataButton();
      await tester.openPage('v020');

      // check the import content
      // await tester.assertCellContent(
      //   rowIndex: 7,
      //   fieldType: FieldType.RichText,
      //   // fieldName: 'Name',
      //   content: '',
      // );

      // check the text cell
      final textCells = <String>['A', 'B', 'C', 'D', 'E', '', '', '', '', ''];
      for (final (index, content) in textCells.indexed) {
        await tester.assertCellContent(
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
        false
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
        ''
      ];
      for (final (index, content) in numberCells.indexed) {
        await tester.assertCellContent(
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
        await tester.assertCellContent(
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
        await tester.assertMultiSelectOption(
          rowIndex: index,
          contents: contents,
        );
      }

      // check the checklist cell
      final List<double> checklistCells = [
        0.6,
        0.3,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
      ];
      for (final (index, percent) in checklistCells.indexed) {
        await tester.assertChecklistCellInGrid(
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
        ''
      ];
      for (final (index, content) in dateCells.indexed) {
        await tester.assertDateCellInGrid(
          rowIndex: index,
          fieldType: FieldType.DateTime,
          content: content,
        );
      }
    });
  });
}
