import 'package:appflowy/plugins/database_view/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/draggable_view_item.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('sidebar test', () {
    testWidgets('create a new page', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // create a new page
      const name = 'Hello AppFlowy';
      await tester.tapNewPageButton();
      await tester.enterText(find.byType(TextFormField), name);
      await tester.tapOKButton();

      // expect to see a new document
      tester.expectToSeePageName(
        name,
      );
      // and with one paragraph block
      expect(find.byType(TextBlockComponentWidget), findsOneWidget);
    });

    testWidgets('create a new document, grid, board and calendar',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      for (final layout in ViewLayoutPB.values) {
        // create a new page
        final name = 'AppFlowy_$layout';
        await tester.createNewPageWithName(
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
            expect(find.byType(TextBlockComponentWidget), findsOneWidget);
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

        await tester.openPage(gettingStated);
      }
    });

    testWidgets('create some nested pages, and move them', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      final names = [1, 2, 3, 4].map((e) => 'document_$e').toList();
      for (var i = 0; i < names.length; i++) {
        final parentName = i == 0 ? gettingStated : names[i - 1];
        await tester.createNewPageWithName(
          name: names[i],
          parentName: parentName,
          layout: ViewLayoutPB.Document,
        );
        tester.expectToSeePageName(names[i], parentName: parentName);
      }

      // move the document_3 to the getting started page
      await tester.movePageToOtherPage(
        name: names[3],
        parentName: gettingStated,
        layout: ViewLayoutPB.Document,
        parentLayout: ViewLayoutPB.Document,
      );
      final fromId = tester
          .widget<SingleInnerViewItem>(tester.findPageName(names[3]))
          .view
          .parentViewId;
      final toId = tester
          .widget<SingleInnerViewItem>(tester.findPageName(gettingStated))
          .view
          .id;
      expect(fromId, toId);

      // move the document_2 before document_1
      await tester.movePageToOtherPage(
        name: names[2],
        parentName: gettingStated,
        layout: ViewLayoutPB.Document,
        parentLayout: ViewLayoutPB.Document,
        position: DraggableHoverPosition.bottom,
      );
      final childViews = tester
          .widget<SingleInnerViewItem>(tester.findPageName(gettingStated))
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
  });
}
