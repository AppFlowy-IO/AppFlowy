import 'package:appflowy/plugins/database_view/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/link_to_page_widget.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
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
    layout,
    name,
  );
  // create a new document
  await tester.createNewPageWithName(
    ViewLayoutPB.Document,
    'insert_a_reference_${layout.name}',
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
