import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('database', () {
    testWidgets('create linked view', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Create board view
      await tester.tapCreateLinkedDatabaseViewButton(DatabaseLayoutPB.Board);
      tester.assertCurrentDatabaseTagIs(DatabaseLayoutPB.Board);

      // Create grid view
      await tester.tapCreateLinkedDatabaseViewButton(DatabaseLayoutPB.Grid);
      tester.assertCurrentDatabaseTagIs(DatabaseLayoutPB.Grid);

      // Create calendar view
      await tester.tapCreateLinkedDatabaseViewButton(DatabaseLayoutPB.Calendar);
      tester.assertCurrentDatabaseTagIs(DatabaseLayoutPB.Calendar);

      await tester.pumpAndSettle();
    });

    testWidgets('rename and delete linked view', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Create board view
      await tester.tapCreateLinkedDatabaseViewButton(DatabaseLayoutPB.Board);
      tester.assertCurrentDatabaseTagIs(DatabaseLayoutPB.Board);

      // rename board view
      await tester.renameLinkedView(
        tester.findTabBarLinkViewByViewLayout(ViewLayoutPB.Board),
        'new board',
      );
      final findBoard = tester.findTabBarLinkViewByViewName('new board');
      expect(findBoard, findsOneWidget);

      // delete the board
      await tester.deleteDatebaseView(findBoard);
      expect(tester.findTabBarLinkViewByViewName('new board'), findsNothing);

      await tester.pumpAndSettle();
    });

    testWidgets('delete the last database view', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Create board view
      await tester.tapCreateLinkedDatabaseViewButton(DatabaseLayoutPB.Board);
      tester.assertCurrentDatabaseTagIs(DatabaseLayoutPB.Board);

      // delete the board
      await tester.deleteDatebaseView(
        tester.findTabBarLinkViewByViewLayout(ViewLayoutPB.Board),
      );

      await tester.pumpAndSettle();
    });
  });
}
