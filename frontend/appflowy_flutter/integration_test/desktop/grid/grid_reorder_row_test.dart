import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checkbox.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import 'grid_test_extensions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid reorder row test:', () {
    testWidgets('base case', (tester) async {
      await tester.openTestDatabase(v069GridFileName);

      // get grid data
      final original = tester.getGridRows();

      // reorder row
      await tester.reorderRow(original[4], original[1]);

      // verify grid data
      List reordered = [
        original[0],
        original[4],
        original[1],
        original[2],
        original[3],
        original[5],
        original[6],
        original[7],
        original[8],
        original[9],
        original[10],
        original[11],
        original[12],
      ];
      List actual = tester.getGridRows();
      expect(actual, orderedEquals(reordered));

      // reorder row
      await tester.reorderRow(reordered[1], reordered[3]);

      // verify grid data
      reordered = [
        original[0],
        original[1],
        original[2],
        original[4],
        original[3],
        original[5],
        original[6],
        original[7],
        original[8],
        original[9],
        original[10],
        original[11],
        original[12],
      ];
      actual = tester.getGridRows();
      expect(actual, orderedEquals(reordered));

      // reorder row
      await tester.reorderRow(reordered[2], reordered[0]);

      // verify grid data
      reordered = [
        original[2],
        original[0],
        original[1],
        original[4],
        original[3],
        original[5],
        original[6],
        original[7],
        original[8],
        original[9],
        original[10],
        original[11],
        original[12],
      ];
      actual = tester.getGridRows();
      expect(actual, orderedEquals(reordered));
    });

    testWidgets('with active sort', (tester) async {
      await tester.openTestDatabase(v069GridFileName);

      // get grid data
      final original = tester.getGridRows();

      // add a sort
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.RichText, 'Name');

      // verify grid data
      final sorted = [
        original[7],
        original[8],
        original[1],
        original[9],
        original[11],
        original[10],
        original[6],
        original[12],
        original[2],
        original[0],
        original[3],
        original[5],
        original[4],
      ];
      List actual = tester.getGridRows();
      expect(actual, orderedEquals(sorted));

      // reorder row
      await tester.reorderRow(original[4], original[1]);

      // verify grid data
      actual = tester.getGridRows();
      // TODO(RS): remind users why the reorder failed
      expect(actual, orderedEquals(sorted));
    });

    testWidgets('with active filter', (tester) async {
      await tester.openTestDatabase(v069GridFileName);

      // get grid data
      final original = tester.getGridRows();

      // add a filter
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

      // reorder row
      await tester.reorderRow(filtered[3], filtered[1]);

      // verify grid data
      List reordered = [
        original[1],
        original[6],
        original[3],
        original[5],
        original[7],
        original[9],
        original[12],
      ];
      actual = tester.getGridRows();
      expect(actual, orderedEquals(reordered));

      // reorder row
      await tester.reorderRow(reordered[3], reordered[5]);

      // verify grid data
      reordered = [
        original[1],
        original[6],
        original[3],
        original[7],
        original[9],
        original[5],
        original[12],
      ];
      actual = tester.getGridRows();
      expect(actual, orderedEquals(reordered));

      // delete the filter
      await tester.tapFilterButtonInGrid('Registration Complete');
      await tester
          .tapDisclosureButtonInFinder(find.byType(CheckboxFilterEditor));
      await tester.tapDeleteFilterButtonInGrid();

      // verify grid data
      final expected = [
        original[0],
        original[1],
        original[2],
        original[6],
        original[3],
        original[4],
        original[7],
        original[8],
        original[9],
        original[5],
        original[10],
        original[11],
        original[12],
      ];
      actual = tester.getGridRows();
      expect(actual, orderedEquals(expected));
    });
  });
}
