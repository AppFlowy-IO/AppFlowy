import 'package:appflowy/plugins/database/grid/presentation/widgets/sort/sort_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid sort:', () {
    testWidgets('text sort', (tester) async {
      await tester.openTestDatabase(v020GridFileName);
      // create a sort
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.RichText, 'Name');

      // check the text cell order
      final textCells = <String>[
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
      ];
      for (final (index, content) in textCells.indexed) {
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.RichText,
          content: content,
        );
      }

      // open the sort menu and select order by descending
      await tester.tapSortMenuInSettingBar();
      await tester.tapEditSortConditionButtonByFieldName('Name');
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
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.RichText,
          content: content,
        );
      }

      // delete all sorts
      await tester.tapSortMenuInSettingBar();
      await tester.tapDeleteAllSortsButton();

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
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.RichText,
          content: content,
        );
      }
      await tester.pumpAndSettle();
    });

    testWidgets('checkbox', (tester) async {
      await tester.openTestDatabase(v020GridFileName);
      // create a sort
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
      await tester.tapEditSortConditionButtonByFieldName('Done');
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

    testWidgets('number', (tester) async {
      await tester.openTestDatabase(v020GridFileName);
      // create a sort
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.Number, 'number');

      // check the number cell order
      for (final (index, content) in <String>[
        '-2',
        '-1',
        '0.1',
        '0.2',
        '1',
        '2',
        '10',
        '11',
        '12',
        '',
      ].indexed) {
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.Number,
          content: content,
        );
      }

      // open the sort menu and select order by descending
      await tester.tapSortMenuInSettingBar();
      await tester.tapEditSortConditionButtonByFieldName('number');
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
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.Number,
          content: content,
        );
      }

      await tester.pumpAndSettle();
    });

    testWidgets('checkbox and number', (tester) async {
      await tester.openTestDatabase(v020GridFileName);
      // create a sort
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.Checkbox, 'Done');

      // open the sort menu and sort checkbox by descending
      await tester.tapSortMenuInSettingBar();
      await tester.tapEditSortConditionButtonByFieldName('Done');
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

      // add another sort, this time by number descending
      await tester.tapSortMenuInSettingBar();
      await tester.tapCreateSortByFieldTypeInSortMenu(
        FieldType.Number,
        'number',
      );
      await tester.tapEditSortConditionButtonByFieldName('number');
      await tester.tapSortByDescending();

      // check checkbox cell order
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

      // check number cell order
      for (final (index, content) in <String>[
        '1',
        '0.2',
        '0.1',
        '-1',
        '-2',
        '12',
        '11',
        '10',
        '2',
        '',
      ].indexed) {
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.Number,
          content: content,
        );
      }

      await tester.pumpAndSettle();
    });

    testWidgets('reorder sort', (tester) async {
      await tester.openTestDatabase(v020GridFileName);
      // create a sort
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.Checkbox, 'Done');

      // open the sort menu and sort checkbox by descending
      await tester.tapSortMenuInSettingBar();
      await tester.tapEditSortConditionButtonByFieldName('Done');
      await tester.tapSortByDescending();

      // add another sort, this time by number descending
      await tester.tapSortMenuInSettingBar();
      await tester.tapCreateSortByFieldTypeInSortMenu(
        FieldType.Number,
        'number',
      );
      await tester.tapEditSortConditionButtonByFieldName('number');
      await tester.tapSortByDescending();

      // check checkbox cell order
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

      // check number cell order
      for (final (index, content) in <String>[
        '1',
        '0.2',
        '0.1',
        '-1',
        '-2',
        '12',
        '11',
        '10',
        '2',
        '',
      ].indexed) {
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.Number,
          content: content,
        );
      }

      // reorder sort
      await tester.tapSortMenuInSettingBar();
      await tester.reorderSort(
        (FieldType.Number, 'number'),
        (FieldType.Checkbox, 'Done'),
      );

      // check checkbox cell order
      for (final (index, content) in <bool>[
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true,
        true,
        false,
      ].indexed) {
        await tester.assertCheckboxCell(
          rowIndex: index,
          isSelected: content,
        );
      }

      // check the number cell order
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
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.Number,
          content: content,
        );
      }
    });

    testWidgets('edit field', (tester) async {
      await tester.openTestDatabase(v020GridFileName);

      // create a number sort
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.Number, 'number');

      // check the number cell order
      for (final (index, content) in <String>[
        '-2',
        '-1',
        '0.1',
        '0.2',
        '1',
        '2',
        '10',
        '11',
        '12',
        '',
      ].indexed) {
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.Number,
          content: content,
        );
      }

      final textCells = <String>[
        'B',
        'A',
        'C',
        'D',
        'E',
        '',
        '',
        '',
        '',
        '',
      ];
      for (final (index, content) in textCells.indexed) {
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.RichText,
          content: content,
        );
      }

      // edit the name of the number field
      await tester.tapGridFieldWithName('number');

      await tester.renameField('hello world');
      await tester.dismissFieldEditor();

      await tester.tapGridFieldWithName('hello world');
      await tester.dismissFieldEditor();

      // expect name to be changed as well
      await tester.tapSortMenuInSettingBar();
      final sortItem = find.ancestor(
        of: find.text('hello world'),
        matching: find.byType(DatabaseSortItem),
      );
      expect(sortItem, findsOneWidget);

      // change the field type of the field to checkbox
      await tester.tapGridFieldWithName('hello world');
      await tester.changeFieldTypeOfFieldWithName(
        'hello world',
        FieldType.Checkbox,
      );

      // expect name to be changed as well
      await tester.tapSortMenuInSettingBar();
      expect(sortItem, findsOneWidget);

      final newTextCells = <String>[
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
      ];
      for (final (index, content) in newTextCells.indexed) {
        tester.assertCellContent(
          rowIndex: index,
          fieldType: FieldType.RichText,
          content: content,
        );
      }
    });
  });
}
