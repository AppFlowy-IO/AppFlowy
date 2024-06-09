import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid', () {
    testWidgets('create row of the grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      await tester.tapCreateRowButtonInGrid();

      // 3 initial rows + 1 created
      await tester.assertNumberOfRowsInGridPage(4);
      await tester.pumpAndSettle();
    });

    testWidgets('create row from row menu of the grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      await tester.hoverOnFirstRowOfGrid();

      await tester.tapCreateRowButtonInRowMenuOfGrid();

      // 3 initial rows + 1 created
      await tester.assertNumberOfRowsInGridPage(4);
      await tester.pumpAndSettle();
    });

    testWidgets('delete row of the grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      await tester.hoverOnFirstRowOfGrid();

      // Open the row menu and then click the delete
      await tester.tapRowMenuButtonInGrid();
      await tester.tapDeleteOnRowMenu();

      // 3 initial rows - 1 deleted
      await tester.assertNumberOfRowsInGridPage(2);
      await tester.pumpAndSettle();
    });

    testWidgets('check number of row indicator in the initial grid',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      await tester.pumpAndSettle();
    });
  });
}
