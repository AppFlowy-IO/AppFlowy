import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checkbox.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:time/time.dart';

import '../../shared/database_test_op.dart';
import 'grid_test_extensions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid edit row test:', () {
    testWidgets('with sort configured', (tester) async {
      await tester.openTestDatabase(v069GridFileName);

      // get grid data
      final unsorted = tester.getGridRows();

      // add a sort
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.RichText, 'Name');

      final sorted = [
        unsorted[7],
        unsorted[8],
        unsorted[1],
        unsorted[9],
        unsorted[11],
        unsorted[10],
        unsorted[6],
        unsorted[12],
        unsorted[2],
        unsorted[0],
        unsorted[3],
        unsorted[5],
        unsorted[4],
      ];

      List actual = tester.getGridRows();
      expect(actual, orderedEquals(sorted));

      await tester.editCell(
        rowIndex: 4,
        fieldType: FieldType.RichText,
        input: "x",
      );
      await tester.pumpAndSettle(200.milliseconds);

      final reSorted = [
        unsorted[7],
        unsorted[8],
        unsorted[1],
        unsorted[9],
        unsorted[10],
        unsorted[6],
        unsorted[12],
        unsorted[2],
        unsorted[0],
        unsorted[3],
        unsorted[5],
        unsorted[11],
        unsorted[4],
      ];

      // verify grid data
      actual = tester.getGridRows();
      expect(actual, orderedEquals(reSorted));

      // delete the sort
      await tester.tapSortMenuInSettingBar();
      await tester.tapDeleteAllSortsButton();

      // verify grid data
      actual = tester.getGridRows();
      expect(actual, orderedEquals(unsorted));
    });

    testWidgets('with filter configured', (tester) async {
      await tester.openTestDatabase(v069GridFileName);

      // get grid data
      final original = tester.getGridRows();

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(
        FieldType.Checkbox,
        'Registration Complete',
      );

      final filtered = [
        original[1],
        original[3],
        original[5],
        original[6],
        original[7],
        original[9],
        original[12],
      ];

      // verify grid data
      List actual = tester.getGridRows();
      expect(actual, orderedEquals(filtered));
      expect(actual.length, equals(7));
      tester.assertNumberOfRowsInGridPage(7);

      await tester.tapCheckboxCellInGrid(rowIndex: 0);
      await tester.pumpAndSettle(200.milliseconds);

      // verify grid data
      actual = tester.getGridRows();
      expect(actual.length, equals(6));
      tester.assertNumberOfRowsInGridPage(6);
      final edited = [
        original[3],
        original[5],
        original[6],
        original[7],
        original[9],
        original[12],
      ];
      expect(actual, orderedEquals(edited));

      // delete the filter
      await tester.tapFilterButtonInGrid('Registration Complete');
      await tester
          .tapDisclosureButtonInFinder(find.byType(CheckboxFilterEditor));
      await tester.tapDeleteFilterButtonInGrid();

      // verify grid data
      actual = tester.getGridRows();
      expect(actual.length, equals(13));
      tester.assertNumberOfRowsInGridPage(13);
    });
  });
}
