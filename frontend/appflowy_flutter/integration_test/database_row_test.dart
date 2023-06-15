import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/database_test_op.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid', () {
    const location = 'appflowy';

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

    testWidgets('create row of the grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();
      await tester.tapCreateRowButtonInGrid();

      // The initial number of rows is 3
      await tester.assertNumberOfRowsInGridPage(4);
      await tester.pumpAndSettle();
    });

    testWidgets('create row from row menu of the grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();
      await tester.hoverOnFirstRowOfGrid();

      await tester.tapCreateRowButtonInRowMenuOfGrid();

      // The initial number of rows is 3
      await tester.assertNumberOfRowsInGridPage(4);
      await tester.assertRowCountInGridPage(4);
      await tester.pumpAndSettle();
    });

    testWidgets('delete row of the grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();
      await tester.hoverOnFirstRowOfGrid();

      // Open the row menu and then click the delete
      await tester.tapRowMenuButtonInGrid();
      await tester.tapDeleteOnRowMenu();

      // The initial number of rows is 3
      await tester.assertNumberOfRowsInGridPage(2);
      await tester.assertRowCountInGridPage(2);
      await tester.pumpAndSettle();
    });

    testWidgets('check number of row indicator in the initial grid',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();
      await tester.assertRowCountInGridPage(3);

      await tester.pumpAndSettle();
    });
  });
}
