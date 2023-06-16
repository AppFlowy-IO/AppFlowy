import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/choicechip/checkbox.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/choicechip/text.dart';
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

    testWidgets('add text filter', (tester) async {
      await tester.openV020database();

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(FieldType.RichText, 'Name');
      await tester.tapFilterButtonInGrid('Name');

      // enter 'A' in the filter text field
      await tester.assertNumberOfRowsInGridPage(10);
      await tester.enterTextInTextFilter('A');
      await tester.assertNumberOfRowsInGridPage(1);

      // after remove the filter, the grid should show all rows
      await tester.enterTextInTextFilter('');
      await tester.assertNumberOfRowsInGridPage(10);

      await tester.enterTextInTextFilter('B');
      await tester.assertNumberOfRowsInGridPage(1);

      // open the menu to delete the filter
      await tester.tapDisclosureButtonInFinder(find.byType(TextFilterEditor));
      await tester.tapDeleteFilterButtonInGrid();
      await tester.assertNumberOfRowsInGridPage(10);

      await tester.pumpAndSettle();
    });

    testWidgets('add checkbox filter', (tester) async {
      await tester.openV020database();

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(FieldType.Checkbox, 'Done');
      await tester.assertNumberOfRowsInGridPage(5);

      await tester.tapFilterButtonInGrid('Done');
      await tester.tapCheckboxFilterButtonInGrid();

      await tester.tapUnCheckedButtonOnCheckboxFilter();
      await tester.assertNumberOfRowsInGridPage(5);

      await tester
          .tapDisclosureButtonInFinder(find.byType(CheckboxFilterEditor));
      await tester.tapDeleteFilterButtonInGrid();
      await tester.assertNumberOfRowsInGridPage(10);

      await tester.pumpAndSettle();
    });

    testWidgets('add checklist filter', (tester) async {
      await tester.openV020database();

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(FieldType.Checklist, 'checklist');

      // By default, the condition of checklist filter is 'uncompleted'
      await tester.assertNumberOfRowsInGridPage(9);

      await tester.tapFilterButtonInGrid('checklist');
      await tester.tapChecklistFilterButtonInGrid();

      await tester.tapCompletedButtonOnChecklistFilter();
      await tester.assertNumberOfRowsInGridPage(1);

      await tester.pumpAndSettle();
    });

    testWidgets('add single select filter', (tester) async {
      await tester.openV020database();

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(FieldType.SingleSelect, 'Type');

      await tester.tapFilterButtonInGrid('Type');

      // select the option 's6'
      await tester.tapOptionFilterWithName('s6');
      await tester.assertNumberOfRowsInGridPage(0);

      // unselect the option 's6'
      await tester.tapOptionFilterWithName('s6');
      await tester.assertNumberOfRowsInGridPage(10);

      // select the option 's5'
      await tester.tapOptionFilterWithName('s5');
      await tester.assertNumberOfRowsInGridPage(1);

      // select the option 's4'
      await tester.tapOptionFilterWithName('s4');

      // The row with 's4' or 's5' should be shown.
      await tester.assertNumberOfRowsInGridPage(2);

      await tester.pumpAndSettle();
    });

    testWidgets('add multi select filter', (tester) async {
      await tester.openV020database();

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(
        FieldType.MultiSelect,
        'multi-select',
      );

      await tester.tapFilterButtonInGrid('multi-select');
      await tester.scrollOptionFilterListByOffset(const Offset(0, -200));

      // select the option 'm1'. Any option with 'm1' should be shown.
      await tester.tapOptionFilterWithName('m1');
      await tester.assertNumberOfRowsInGridPage(5);
      await tester.tapOptionFilterWithName('m1');

      // select the option 'm2'. Any option with 'm2' should be shown.
      await tester.tapOptionFilterWithName('m2');
      await tester.assertNumberOfRowsInGridPage(4);
      await tester.tapOptionFilterWithName('m2');

      // select the option 'm4'. Any option with 'm4' should be shown.
      await tester.tapOptionFilterWithName('m4');
      await tester.assertNumberOfRowsInGridPage(1);

      await tester.pumpAndSettle();
    });
  });
}
