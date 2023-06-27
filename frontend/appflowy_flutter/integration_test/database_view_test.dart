import 'package:appflowy/plugins/database_view/tar_bar/tar_bar_add_button.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/database_test_op.dart';
import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('database', () {
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

    testWidgets('create linked view', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Create board view
      await tester.tapCreateLinkedDatabaseViewButton(AddButtonAction.board);
      tester.assertCurrentDatabaseTagIs(DatabaseLayoutPB.Board);

      // Create grid view
      await tester.tapCreateLinkedDatabaseViewButton(AddButtonAction.grid);
      tester.assertCurrentDatabaseTagIs(DatabaseLayoutPB.Grid);

      // Create calendar view
      await tester.tapCreateLinkedDatabaseViewButton(AddButtonAction.calendar);
      tester.assertCurrentDatabaseTagIs(DatabaseLayoutPB.Calendar);

      await tester.pumpAndSettle();
    });

    testWidgets('rename and delete linked view', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Create board view
      await tester.tapCreateLinkedDatabaseViewButton(AddButtonAction.board);
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
      await tester.tapGoButton();

      await tester.tapAddButton();
      await tester.tapCreateGridButton();

      // Create board view
      await tester.tapCreateLinkedDatabaseViewButton(AddButtonAction.board);
      tester.assertCurrentDatabaseTagIs(DatabaseLayoutPB.Board);

      // delete the board
      await tester.deleteDatebaseView(
        tester.findTabBarLinkViewByViewLayout(ViewLayoutPB.Board),
      );

      await tester.pumpAndSettle();
    });
  });
}
