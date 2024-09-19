import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import 'grid_test_extensions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid simultaneous sort and filter test:', () {
    // testWidgets('delete filter with active sort', (tester) async {
    //   await tester.openTestDatabase(v069GridFileName);

    //   // get grid data
    //   final original = tester.getGridRows();

    //   // add a filter
    //   await tester.tapDatabaseFilterButton();
    //   await tester.tapCreateFilterByFieldType(
    //     FieldType.Checkbox,
    //     'Registration Complete',
    //   );

    //   // add a sort
    //   await tester.tapDatabaseSortButton();
    //   await tester.tapCreateSortByFieldType(FieldType.RichText, 'Name');

    //   final filteredAndSorted = [
    //     original[7],
    //     original[1],
    //     original[9],
    //     original[6],
    //     original[12],
    //     original[3],
    //     original[5],
    //   ];

    //   // verify grid data
    //   List actual = tester.getGridRows();
    //   expect(actual, orderedEquals(filteredAndSorted));

    //   // delete the filter
    //   await tester.tapFilterButtonInGrid('Registration Complete');
    //   await tester
    //       .tapDisclosureButtonInFinder(find.byType(CheckboxFilterEditor));
    //   await tester.tapDeleteFilterButtonInGrid();

    //   final sorted = [
    //     original[7],
    //     original[8],
    //     original[1],
    //     original[9],
    //     original[11],
    //     original[10],
    //     original[6],
    //     original[12],
    //     original[2],
    //     original[0],
    //     original[3],
    //     original[5],
    //     original[4],
    //   ];

    //   // verify grid data
    //   actual = tester.getGridRows();
    //   expect(actual, orderedEquals(sorted));
    // });

    testWidgets('delete sort with active fiilter', (tester) async {
      await tester.openTestDatabase(v069GridFileName);

      // get grid data
      final original = tester.getGridRows();

      // add a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(
        FieldType.Checkbox,
        'Registration Complete',
      );

      // add a sort
      await tester.tapDatabaseSortButton();
      await tester.tapCreateSortByFieldType(FieldType.RichText, 'Name');

      final filteredAndSorted = [
        original[7],
        original[1],
        original[9],
        original[6],
        original[12],
        original[3],
        original[5],
      ];

      // verify grid data
      List actual = tester.getGridRows();
      expect(actual, orderedEquals(filteredAndSorted));

      // delete the sort
      await tester.tapSortMenuInSettingBar();
      await tester.tapDeleteAllSortsButton();

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
      actual = tester.getGridRows();
      expect(actual, orderedEquals(filtered));
    });
  });
}
