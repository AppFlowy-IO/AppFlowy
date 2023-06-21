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

    testWidgets('add all sorts', (tester) async {
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

      await tester.tapSortMenuInSettingBar();
      await tester.tapAllSortButton();

      // check the text cell order
      final cells = <String>[
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
      for (final (index, content) in cells.indexed) {
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
