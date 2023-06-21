import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/database_test_op.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid', () {
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

    testWidgets('add text sort', (tester) async {
      await tester.openV020database();
      // create a filter
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.RichText, 'Name');

      // check the text cell order
      final textCells = <String>[
        '',
        '',
        '',
        '',
        '',
        'A',
        'B',
        'C',
        'D',
        'E',
      ];
      for (final (index, content) in textCells.indexed) {
        await tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.RichText,
          content: content,
        );
      }

      // open the sort menu and select order by descending
      await tester.tapSortMenuInSettingBar();
      await tester.tapSortButtonByName('Name');
      await tester.tapSortByDescending();
      for (final (index, content) in <String>[
        'E',
        'D',
        'C',
        'B',
        'A',
        '',
        '',
        '',
        '',
        '',
      ].indexed) {
        await tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.RichText,
          content: content,
        );
      }

      // delete all sorts
      await tester.tapSortMenuInSettingBar();
      await tester.tapAllSortButton();

      // check the text cell order
      for (final (index, content) in <String>[
        'A',
        'B',
        'C',
        'D',
        'E',
        '',
        '',
        '',
        '',
        '',
      ].indexed) {
        await tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.RichText,
          content: content,
        );
      }
      await tester.pumpAndSettle();
    });

    testWidgets('add checkbox sort', (tester) async {
      await tester.openV020database();
      // create a filter
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.Checkbox, 'Done');

      // check the checkbox cell order
      for (final (index, content) in <bool>[
        false,
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true,
        true,
      ].indexed) {
        await tester.assertCheckboxCell(
          rowIndex: index,
          isSelected: content,
        );
      }

      // open the sort menu and select order by descending
      await tester.tapSortMenuInSettingBar();
      await tester.tapSortButtonByName('Done');
      await tester.tapSortByDescending();
      for (final (index, content) in <bool>[
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
      ].indexed) {
        await tester.assertCheckboxCell(
          rowIndex: index,
          isSelected: content,
        );
      }

      await tester.pumpAndSettle();
    });

    testWidgets('add number sort', (tester) async {
      await tester.openV020database();
      // create a filter
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.Number, 'number');

      // check the number cell order
      for (final (index, content) in <String>[
        '',
        '-2',
        '-1',
        '0.1',
        '0.2',
        '1',
        '2',
        '10',
        '11',
        '12',
      ].indexed) {
        await tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.Number,
          content: content,
        );
      }

      // open the sort menu and select order by descending
      await tester.tapSortMenuInSettingBar();
      await tester.tapSortButtonByName('number');
      await tester.tapSortByDescending();
      for (final (index, content) in <String>[
        '12',
        '11',
        '10',
        '2',
        '1',
        '0.2',
        '0.1',
        '-1',
        '-2',
        '',
      ].indexed) {
        await tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.Number,
          content: content,
        );
      }

      await tester.pumpAndSettle();
    });

    testWidgets('add number and text sort', (tester) async {
      await tester.openV020database();
      // create a filter
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.Number, 'number');

      // open the sort menu and select number order by descending
      await tester.tapSortMenuInSettingBar();
      await tester.tapSortButtonByName('number');
      await tester.tapSortByDescending();
      for (final (index, content) in <String>[
        '12',
        '11',
        '10',
        '2',
        '1',
        '0.2',
        '0.1',
        '-1',
        '-2',
        '',
      ].indexed) {
        await tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.Number,
          content: content,
        );
      }

      await tester.tapSortMenuInSettingBar();
      await tester.tapCreateSortByFieldTypeInSortMenu(
        FieldType.RichText,
        'Name',
      );

      // check number cell order
      for (final (index, content) in <String>[
        '12',
        '11',
        '10',
        '2',
        '',
        '-1',
        '-2',
        '0.1',
        '0.2',
        '1',
      ].indexed) {
        await tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.Number,
          content: content,
        );
      }

      // check text cell order
      for (final (index, content) in <String>[
        '',
        '',
        '',
        '',
        '',
        'A',
        'B',
        'C',
        'D',
        'E',
      ].indexed) {
        await tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.RichText,
          content: content,
        );
      }

      await tester.pumpAndSettle();
    });
  });
}
