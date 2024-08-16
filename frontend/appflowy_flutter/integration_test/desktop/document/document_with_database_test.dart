import 'package:appflowy/plugins/database/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/text.dart';
import 'package:appflowy/plugins/inline_actions/widgets/inline_actions_handler.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/uuid.dart';
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
  });
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
