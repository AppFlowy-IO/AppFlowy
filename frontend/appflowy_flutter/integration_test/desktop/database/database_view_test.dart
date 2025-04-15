import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    testWidgets('insert grid in column', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      /// create page and show slash menu
      await tester.createNewPageWithNameUnderParent(name: 'test page');
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.pumpAndSettle();

      /// create a column
      await tester.editor.tapSlashMenuItemWithName(
        LocaleKeys.document_slashMenu_name_twoColumns.tr(),
      );
      final actionList = find.byType(BlockActionList);
      expect(actionList, findsNWidgets(2));
      final position = tester.getCenter(actionList.last);

      /// tap the second child of column
      await tester.tapAt(position.copyWith(dx: position.dx + 50));

      /// create a grid
      await tester.editor.showSlashMenu();
      await tester.pumpAndSettle();
      await tester.editor.tapSlashMenuItemWithName(
        LocaleKeys.document_slashMenu_name_grid.tr(),
      );

      final grid = find.byType(GridPageContent);
      expect(grid, findsOneWidget);
    });
  });
}
