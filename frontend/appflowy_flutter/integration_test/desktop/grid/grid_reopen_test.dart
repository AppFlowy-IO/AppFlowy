import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checkbox.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';
import 'grid_test_extensions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid reopen test:', () {
    testWidgets('base case', (tester) async {
      await tester.openTestDatabase(v069GridFileName);

      final expected = tester.getGridRows();

      // go to another page and come back
      await tester.openPage('Getting started');
      await tester.openPage('v069', layout: ViewLayoutPB.Grid);

      // verify grid data
      final actual = tester.getGridRows();

      expect(actual, orderedEquals(expected));
    });

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

      // verify grid data
      List actual = tester.getGridRows();
      expect(actual, orderedEquals(sorted));

      // go to another page and come back
      await tester.openPage('Getting started');
      await tester.openPage('v069', layout: ViewLayoutPB.Grid);

      // verify grid data
      actual = tester.getGridRows();
      expect(actual, orderedEquals(sorted));

      // delete sorts
      // TODO(RS): Shouldn't the sort/filter list show automatically!?
      await tester.tapDatabaseSortButton();
      await tester.tapSortMenuInSettingBar();
      await tester.tapDeleteAllSortsButton();

      // verify grid data
      actual = tester.getGridRows();
      expect(actual, orderedEquals(unsorted));

      // go to another page and come back
      await tester.openPage('Getting started');
      await tester.openPage('v069', layout: ViewLayoutPB.Grid);

      // verify grid data
      actual = tester.getGridRows();
      expect(actual, orderedEquals(unsorted));
    });

    testWidgets('with filter configured', (tester) async {
      await tester.openTestDatabase(v069GridFileName);

      // get grid data
      final unfiltered = tester.getGridRows();

      // add a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(
        FieldType.Checkbox,
        'Registration Complete',
      );

      final filtered = [
        unfiltered[1],
        unfiltered[3],
        unfiltered[5],
        unfiltered[6],
        unfiltered[7],
        unfiltered[9],
        unfiltered[12],
      ];

      // verify grid data
      List actual = tester.getGridRows();
      expect(actual, orderedEquals(filtered));

      // go to another page and come back
      await tester.openPage('Getting started');
      await tester.openPage('v069', layout: ViewLayoutPB.Grid);

      // verify grid data
      actual = tester.getGridRows();
      expect(actual, orderedEquals(filtered));

      // delete the filter
      // TODO(RS): Shouldn't the sort/filter list show automatically!?
      await tester.tapDatabaseFilterButton();
      await tester.tapFilterButtonInGrid('Registration Complete');
      await tester
          .tapDisclosureButtonInFinder(find.byType(CheckboxFilterEditor));
      await tester.tapDeleteFilterButtonInGrid();

      // verify grid data
      actual = tester.getGridRows();
      expect(actual, orderedEquals(unfiltered));

      // go to another page and come back
      await tester.openPage('Getting started');
      await tester.openPage('v069', layout: ViewLayoutPB.Grid);

      // verify grid data
      actual = tester.getGridRows();
      expect(actual, orderedEquals(unfiltered));
    });

    testWidgets('with both filter and sort configured', (tester) async {
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

      // go to another page and come back
      await tester.openPage('Getting started');
      await tester.openPage('v069', layout: ViewLayoutPB.Grid);

      // verify grid data
      actual = tester.getGridRows();
      expect(actual, orderedEquals(filteredAndSorted));
    });
  });
}
