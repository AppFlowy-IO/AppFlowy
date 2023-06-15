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
      await tester.tapTextFilterDisclosureButtonInGrid();
      await tester.tapDeleteTextFilterButtonInGrid();
      await tester.assertNumberOfRowsInGridPage(10);

      await tester.pumpAndSettle();
    });

    testWidgets('add checklist filter', (tester) async {
      await tester.openV020database();

      // create a filter
      await tester.tapDatabaseFilterButton();
      await tester.tapCreateFilterByFieldType(FieldType.Checkbox, 'Done');
      await tester.assertNumberOfRowsInGridPage(5);

      await tester.tapFilterButtonInGrid('Done');
      await tester.tapCheckboxFilterButtonInGrid();

      await tester.tapUnCheckedButtonOnCheckboxFilter();
      await tester.assertNumberOfRowsInGridPage(5);

      await tester.pumpAndSettle();
    });
  });
}
