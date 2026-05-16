import 'package:appflowy/plugins/database/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/footer/grid_footer.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/row/row.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/text.dart';
import 'package:appflowy/plugins/inline_actions/widgets/inline_actions_handler.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('database view in document', () {
    testWidgets('insert a referenced grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await insertLinkedDatabase(tester, ViewLayoutPB.Grid);

      // validate the referenced grid is inserted
      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.byType(GridPage),
        ),
        findsOneWidget,
      );

      // https://github.com/AppFlowy-IO/AppFlowy/issues/3533
      // test: the selection of editor should be clear when editing the grid
      await tester.editor.updateSelection(
        Selection.collapsed(
          Position(path: [1]),
        ),
      );
      final gridTextCell = find.byType(EditableTextCell).first;
      await tester.tapButton(gridTextCell);

      expect(tester.editor.getCurrentEditorState().selection, isNull);
    });

    testWidgets('insert a referenced board', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await insertLinkedDatabase(tester, ViewLayoutPB.Board);

      // validate the referenced board is inserted
      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.byType(DesktopBoardPage),
        ),
        findsOneWidget,
      );
    });

    testWidgets('insert multiple referenced boards', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new grid
      final id = uuid();
      final name = '${ViewLayoutPB.Board.name}_$id';
      await tester.createNewPageWithNameUnderParent(
        name: name,
        layout: ViewLayoutPB.Board,
        openAfterCreated: false,
      );
      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: 'insert_a_reference_${ViewLayoutPB.Board.name}',
      );
      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      // insert a referenced view
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName(
        ViewLayoutPB.Board.slashMenuLinkedName,
      );
      final referencedDatabase1 = find.descendant(
        of: find.byType(InlineActionsHandler),
        matching: find.findTextInFlowyText(name),
      );
      expect(referencedDatabase1, findsOneWidget);
      await tester.tapButton(referencedDatabase1);

      await tester.editor.tapLineOfEditorAt(1);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName(
        ViewLayoutPB.Board.slashMenuLinkedName,
      );
      final referencedDatabase2 = find.descendant(
        of: find.byType(InlineActionsHandler),
        matching: find.findTextInFlowyText(name),
      );
      expect(referencedDatabase2, findsOneWidget);
      await tester.tapButton(referencedDatabase2);

      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.byType(DesktopBoardPage),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('insert a referenced calendar', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await insertLinkedDatabase(tester, ViewLayoutPB.Calendar);

      // validate the referenced grid is inserted
      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.byType(CalendarPage),
        ),
        findsOneWidget,
      );
    });

    testWidgets('create a grid inside a document', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await createInlineDatabase(tester, ViewLayoutPB.Grid);

      // validate the inline grid is created
      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.byType(GridPage),
        ),
        findsOneWidget,
      );
    });

    testWidgets('create a board inside a document', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await createInlineDatabase(tester, ViewLayoutPB.Board);

      // validate the inline board is created
      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.byType(DesktopBoardPage),
        ),
        findsOneWidget,
      );
    });

    testWidgets('create a calendar inside a document', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await createInlineDatabase(tester, ViewLayoutPB.Calendar);

      // validate the inline calendar is created
      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.byType(CalendarPage),
        ),
        findsOneWidget,
      );
    });

    testWidgets('insert a referenced grid with many rows (load more option)',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await insertLinkedDatabase(tester, ViewLayoutPB.Grid);

      // validate the referenced grid is inserted
      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.byType(GridPage),
        ),
        findsOneWidget,
      );

      // https://github.com/AppFlowy-IO/AppFlowy/issues/3533
      // test: the selection of editor should be clear when editing the grid
      await tester.editor.updateSelection(
        Selection.collapsed(
          Position(path: [1]),
        ),
      );
      final gridTextCell = find.byType(EditableTextCell).first;
      await tester.tapButton(gridTextCell);

      expect(tester.editor.getCurrentEditorState().selection, isNull);

      final editorScrollable = find
          .descendant(
            of: find.byType(AppFlowyEditor),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axis == Axis.vertical,
            ),
          )
          .first;

      // Add 100 Rows to the linked database
      final addRowFinder = find.byType(GridAddRowButton);
      for (var i = 0; i < 100; i++) {
        await tester.scrollUntilVisible(
          addRowFinder,
          100,
          scrollable: editorScrollable,
        );
        await tester.tapButton(addRowFinder);
        await tester.pumpAndSettle();
      }

      // Since all rows visible are those we added, we should see all of them
      expect(find.byType(GridRow), findsNWidgets(103));

      // Navigate to getting started
      await tester.openPage(gettingStarted);

      // Navigate back to the document
      await tester.openPage('insert_a_reference_${ViewLayoutPB.Grid.name}');

      // We see only 25 Grid Rows
      expect(find.byType(GridRow), findsNWidgets(25));

      // We see Add row and load more button
      expect(find.byType(GridAddRowButton), findsOneWidget);
      expect(find.byType(GridRowLoadMoreButton), findsOneWidget);

      // Load more rows, expect 50 visible
      await _loadMoreRows(tester, editorScrollable, 50);

      // Load more rows, expect 75 visible
      await _loadMoreRows(tester, editorScrollable, 75);

      // Load more rows, expect 100 visible
      await _loadMoreRows(tester, editorScrollable, 100);

      // Load more rows, expect 103 visible
      await _loadMoreRows(tester, editorScrollable, 103);

      // We no longer see load more option
      expect(find.byType(GridRowLoadMoreButton), findsNothing);
    });
  });
}

Future<void> _loadMoreRows(
  WidgetTester tester,
  Finder scrollable, [
  int? expectedRows,
]) async {
  await tester.scrollUntilVisible(
    find.byType(GridRowLoadMoreButton),
    100,
    scrollable: scrollable,
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byType(GridRowLoadMoreButton));
  await tester.pumpAndSettle();

  if (expectedRows != null) {
    expect(find.byType(GridRow), findsNWidgets(expectedRows));
  }
}

/// Insert a referenced database of [layout] into the document
Future<void> insertLinkedDatabase(
  WidgetTester tester,
  ViewLayoutPB layout,
) async {
  // create a new grid
  final id = uuid();
  final name = '${layout.name}_$id';
  await tester.createNewPageWithNameUnderParent(
    name: name,
    layout: layout,
    openAfterCreated: false,
  );
  // create a new document
  await tester.createNewPageWithNameUnderParent(
    name: 'insert_a_reference_${layout.name}',
  );
  // tap the first line of the document
  await tester.editor.tapLineOfEditorAt(0);
  // insert a referenced view
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName(
    layout.slashMenuLinkedName,
  );

  final linkToPageMenu = find.byType(InlineActionsHandler);
  expect(linkToPageMenu, findsOneWidget);
  final referencedDatabase = find.descendant(
    of: linkToPageMenu,
    matching: find.findTextInFlowyText(name),
  );
  expect(referencedDatabase, findsOneWidget);
  await tester.tapButton(referencedDatabase);
}

Future<void> createInlineDatabase(
  WidgetTester tester,
  ViewLayoutPB layout,
) async {
  // create a new document
  final documentName = 'insert_a_inline_${layout.name}';
  await tester.createNewPageWithNameUnderParent(
    name: documentName,
  );
  // tap the first line of the document
  await tester.editor.tapLineOfEditorAt(0);
  // insert a referenced view
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName(
    layout.slashMenuName,
    offset: 100,
  );
  await tester.pumpAndSettle();

  final childViews = tester
      .widget<SingleInnerViewItem>(tester.findPageName(documentName))
      .view
      .childViews;
  expect(childViews.length, 1);
}
