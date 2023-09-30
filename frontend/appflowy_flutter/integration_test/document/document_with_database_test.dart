import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/link_to_page_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('database view in document', () {
    testWidgets('insert a referenced grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await insertReferenceDatabase(tester, ViewLayoutPB.Grid);

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
      final gridTextCell = find.byType(GridTextCell).first;
      await tester.tapButton(gridTextCell);

      expect(tester.editor.getCurrentEditorState().selection, isNull);
    });

    testWidgets('insert a referenced board', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await insertReferenceDatabase(tester, ViewLayoutPB.Board);

      // validate the referenced board is inserted
      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.byType(BoardPage),
        ),
        findsOneWidget,
      );
    });

    testWidgets('insert a referenced calendar', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await insertReferenceDatabase(tester, ViewLayoutPB.Calendar);

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
      await tester.tapGoButton();

      await createInlineDatabase(tester, ViewLayoutPB.Grid);

      // validate the referenced grid is inserted
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
      await tester.tapGoButton();

      await createInlineDatabase(tester, ViewLayoutPB.Board);

      // validate the referenced grid is inserted
      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.byType(BoardPage),
        ),
        findsOneWidget,
      );
    });

    testWidgets('create a calendar inside a document', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await createInlineDatabase(tester, ViewLayoutPB.Calendar);

      // validate the referenced grid is inserted
      expect(
        find.descendant(
          of: find.byType(AppFlowyEditor),
          matching: find.byType(CalendarPage),
        ),
        findsOneWidget,
      );
    });
  });
}

/// Insert a referenced database of [layout] into the document
Future<void> insertReferenceDatabase(
  WidgetTester tester,
  ViewLayoutPB layout,
) async {
  // create a new grid
  final id = uuid();
  final name = '${layout.name}_$id';
  await tester.createNewPageWithName(
    name: name,
    layout: layout,
    openAfterCreated: false,
  );
  // create a new document
  await tester.createNewPageWithName(
    name: 'insert_a_reference_${layout.name}',
    layout: ViewLayoutPB.Document,
    openAfterCreated: true,
  );
  // tap the first line of the document
  await tester.editor.tapLineOfEditorAt(0);
  // insert a referenced view
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName(
    layout.referencedMenuName,
  );

  final linkToPageMenu = find.byType(LinkToPageMenu);
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
  await tester.createNewPageWithName(
    name: documentName,
    layout: ViewLayoutPB.Document,
    openAfterCreated: true,
  );
  // tap the first line of the document
  await tester.editor.tapLineOfEditorAt(0);
  // insert a referenced view
  await tester.editor.showSlashMenu();
  final name = switch (layout) {
    ViewLayoutPB.Grid => LocaleKeys.document_slashMenu_grid_createANewGrid.tr(),
    ViewLayoutPB.Board =>
      LocaleKeys.document_slashMenu_board_createANewBoard.tr(),
    ViewLayoutPB.Calendar =>
      LocaleKeys.document_slashMenu_calendar_createANewCalendar.tr(),
    _ => '',
  };
  await tester.editor.tapSlashMenuItemWithName(
    name,
  );
  await tester.pumpAndSettle();

  final childViews = tester
      .widget<SingleInnerViewItem>(tester.findPageName(documentName))
      .view
      .childViews;
  expect(childViews.length, 1);
}
