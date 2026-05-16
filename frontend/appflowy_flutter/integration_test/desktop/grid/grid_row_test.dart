import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checkbox.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

import 'grid_test_extensions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('grid row test:', () {
    testWidgets('create from the bottom', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      final expected = tester.getGridRows();

      // create row
      await tester.tapCreateRowButtonInGrid();

      final actual = tester.getGridRows();
      expect(actual.slice(0, 3), orderedEquals(expected));
      expect(actual.length, equals(4));
      tester.assertNumberOfRowsInGridPage(4);
    });

    testWidgets('create from a row\'s menu', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      final expected = tester.getGridRows();

      // create row
      await tester.hoverOnFirstRowOfGrid();
      await tester.tapCreateRowButtonAfterHoveringOnGridRow();

      final actual = tester.getGridRows();
      expect([actual[0], actual[2], actual[3]], orderedEquals(expected));
      expect(actual.length, equals(4));
      tester.assertNumberOfRowsInGridPage(4);
    });

    testWidgets('create with sort configured', (tester) async {
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

      List actual = tester.getGridRows();
      expect(actual, orderedEquals(sorted));

      // create row
      await tester.hoverOnFirstRowOfGrid();
      await tester.tapCreateRowButtonAfterHoveringOnGridRow();

      // cancel
      expect(find.byType(ConfirmPopup), findsOneWidget);
      await tester.tapButtonWithName(LocaleKeys.button_cancel.tr());

      // verify grid data
      actual = tester.getGridRows();
      expect(actual, orderedEquals(sorted));

      // try again, but confirm this time
      await tester.hoverOnFirstRowOfGrid();
      await tester.tapCreateRowButtonAfterHoveringOnGridRow();
      expect(find.byType(ConfirmPopup), findsOneWidget);
      await tester.tapButtonWithName(LocaleKeys.button_remove.tr());

      // verify grid data
      actual = tester.getGridRows();
      expect(actual.length, equals(14));
      tester.assertNumberOfRowsInGridPage(14);
    });

    testWidgets('create with filter configured', (tester) async {
      await tester.openTestDatabase(v069GridFileName);

      // get grid data
      final original = tester.getGridRows();

      // create a filter
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

      // create row (one before and after the first row, and one at the bottom)
      await tester.tapCreateRowButtonInGrid();
      await tester.hoverOnFirstRowOfGrid();
      await tester.tapCreateRowButtonAfterHoveringOnGridRow();
      await tester.hoverOnFirstRowOfGrid(() async {
        await tester.tapRowMenuButtonInGrid();
        await tester.tapCreateRowAboveButtonInRowMenu();
      });

      actual = tester.getGridRows();
      expect(actual.length, equals(10));
      tester.assertNumberOfRowsInGridPage(10);
      actual = [
        actual[1],
        actual[3],
        actual[4],
        actual[5],
        actual[6],
        actual[7],
        actual[8],
      ];
      expect(actual, orderedEquals(filtered));

      // delete the filter
      await tester.tapFilterButtonInGrid('Registration Complete');
      await tester
          .tapDisclosureButtonInFinder(find.byType(CheckboxFilterEditor));
      await tester.tapDeleteFilterButtonInGrid();

      // verify grid data
      actual = tester.getGridRows();
      expect(actual.length, equals(16));
      tester.assertNumberOfRowsInGridPage(16);
      actual = [
        actual[0],
        actual[2],
        actual[4],
        actual[5],
        actual[6],
        actual[7],
        actual[8],
        actual[9],
        actual[10],
        actual[11],
        actual[12],
        actual[13],
        actual[14],
      ];
      expect(actual, orderedEquals(original));
    });

    testWidgets('delete row of the grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      await tester.hoverOnFirstRowOfGrid(() async {
        // Open the row menu and click the delete button
        await tester.tapRowMenuButtonInGrid();
        await tester.tapDeleteOnRowMenu();
      });
      expect(find.byType(ConfirmPopup), findsOneWidget);
      await tester.tapButtonWithName(LocaleKeys.button_delete.tr());

      tester.assertNumberOfRowsInGridPage(2);
    });

    testWidgets('delete row in two views', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      await tester.renameLinkedView(
        tester.findTabBarLinkViewByViewLayout(ViewLayoutPB.Grid),
        'grid 1',
      );
      tester.assertNumberOfRowsInGridPage(3);

      await tester.tapCreateLinkedDatabaseViewButton(DatabaseLayoutPB.Grid);
      await tester.renameLinkedView(
        tester.findTabBarLinkViewByViewLayout(ViewLayoutPB.Grid).at(1),
        'grid 2',
      );
      tester.assertNumberOfRowsInGridPage(3);

      await tester.hoverOnFirstRowOfGrid(() async {
        // Open the row menu and click the delete button
        await tester.tapRowMenuButtonInGrid();
        await tester.tapDeleteOnRowMenu();
      });
      expect(find.byType(ConfirmPopup), findsOneWidget);
      await tester.tapButtonWithName(LocaleKeys.button_delete.tr());
      // 3 initial rows - 1 deleted
      tester.assertNumberOfRowsInGridPage(2);

      await tester.tapTabBarLinkedViewByViewName('grid 1');
      tester.assertNumberOfRowsInGridPage(2);
    });
  });
}
