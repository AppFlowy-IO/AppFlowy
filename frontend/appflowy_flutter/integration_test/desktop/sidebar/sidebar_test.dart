import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/draggable_view_item.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_add_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_more_action_button.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('sidebar test', () {
    testWidgets('create a new page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new page
      await tester.tapNewPageButton();

      // expect to see a new document
      tester.expectToSeePageName(
        LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
      );
      // and with one paragraph block
      expect(find.byType(ParagraphBlockComponentWidget), findsOneWidget);
    });

    testWidgets('create a new document, grid, board and calendar',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      for (final layout in ViewLayoutPB.values) {
        // create a new page
        final name = 'AppFlowy_$layout';
        await tester.createNewPageWithNameUnderParent(
          name: name,
          layout: layout,
        );

        // expect to see a new page
        tester.expectToSeePageName(
          name,
          layout: layout,
        );

        switch (layout) {
          case ViewLayoutPB.Document:
            // and with one paragraph block
            expect(find.byType(ParagraphBlockComponentWidget), findsOneWidget);
            break;
          case ViewLayoutPB.Grid:
            expect(find.byType(GridPage), findsOneWidget);
            break;
          case ViewLayoutPB.Board:
            expect(find.byType(BoardPage), findsOneWidget);
            break;
          case ViewLayoutPB.Calendar:
            expect(find.byType(CalendarPage), findsOneWidget);
            break;
        }

        await tester.openPage(gettingStarted);
      }
    });

    testWidgets('create some nested pages, and move them', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      final names = [1, 2, 3, 4].map((e) => 'document_$e').toList();
      for (var i = 0; i < names.length; i++) {
        final parentName = i == 0 ? gettingStarted : names[i - 1];
        await tester.createNewPageWithNameUnderParent(
          name: names[i],
          parentName: parentName,
        );
        tester.expectToSeePageName(names[i], parentName: parentName);
      }

      // move the document_3 to the getting started page
      await tester.movePageToOtherPage(
        name: names[3],
        parentName: gettingStarted,
        layout: ViewLayoutPB.Document,
        parentLayout: ViewLayoutPB.Document,
      );
      final fromId = tester
          .widget<SingleInnerViewItem>(tester.findPageName(names[3]))
          .view
          .parentViewId;
      final toId = tester
          .widget<SingleInnerViewItem>(tester.findPageName(gettingStarted))
          .view
          .id;
      expect(fromId, toId);

      // move the document_2 before document_1
      await tester.movePageToOtherPage(
        name: names[2],
        parentName: gettingStarted,
        layout: ViewLayoutPB.Document,
        parentLayout: ViewLayoutPB.Document,
        position: DraggableHoverPosition.bottom,
      );
      final childViews = tester
          .widget<SingleInnerViewItem>(tester.findPageName(gettingStarted))
          .view
          .childViews;
      expect(
        childViews[0].id,
        tester
            .widget<SingleInnerViewItem>(tester.findPageName(names[2]))
            .view
            .id,
      );
      expect(
        childViews[1].id,
        tester
            .widget<SingleInnerViewItem>(tester.findPageName(names[0]))
            .view
            .id,
      );
      expect(
        childViews[2].id,
        tester
            .widget<SingleInnerViewItem>(tester.findPageName(names[3]))
            .view
            .id,
      );
    });

    testWidgets('unable to move a document into a database', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      const document = 'document';
      await tester.createNewPageWithNameUnderParent(
        name: document,
        openAfterCreated: false,
      );
      tester.expectToSeePageName(document);

      const grid = 'grid';
      await tester.createNewPageWithNameUnderParent(
        name: grid,
        layout: ViewLayoutPB.Grid,
        openAfterCreated: false,
      );
      tester.expectToSeePageName(grid, layout: ViewLayoutPB.Grid);

      // move the document to the grid page
      await tester.movePageToOtherPage(
        name: document,
        parentName: grid,
        layout: ViewLayoutPB.Document,
        parentLayout: ViewLayoutPB.Grid,
      );

      // it should not be moved
      final childViews = tester
          .widget<SingleInnerViewItem>(tester.findPageName(gettingStarted))
          .view
          .childViews;
      expect(
        childViews[0].name,
        document,
      );
      expect(
        childViews[1].name,
        grid,
      );
    });

    testWidgets('unable to create a new database inside the existing one',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      const grid = 'grid';
      await tester.createNewPageWithNameUnderParent(
        name: grid,
        layout: ViewLayoutPB.Grid,
      );
      tester.expectToSeePageName(grid, layout: ViewLayoutPB.Grid);

      await tester.hoverOnPageName(
        grid,
        layout: ViewLayoutPB.Grid,
        onHover: () async {
          expect(find.byType(ViewAddButton), findsNothing);
          expect(find.byType(ViewMoreActionButton), findsOneWidget);
        },
      );
    });
  });
}
