import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/shared/flowy_error_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('inline page view in document', () {
    testWidgets('insert a inline page - grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await insertInlinePage(tester, ViewLayoutPB.Grid);

      final mentionBlock = find.byType(MentionPageBlock);
      expect(mentionBlock, findsOneWidget);
      await tester.tapButton(mentionBlock);
    });

    testWidgets('insert a inline page - board', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await insertInlinePage(tester, ViewLayoutPB.Board);

      final mentionBlock = find.byType(MentionPageBlock);
      expect(mentionBlock, findsOneWidget);
      await tester.tapButton(mentionBlock);
    });

    testWidgets('insert a inline page - calendar', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await insertInlinePage(tester, ViewLayoutPB.Calendar);

      final mentionBlock = find.byType(MentionPageBlock);
      expect(mentionBlock, findsOneWidget);
      await tester.tapButton(mentionBlock);
    });

    testWidgets('insert a inline page - document', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await insertInlinePage(tester, ViewLayoutPB.Document);

      final mentionBlock = find.byType(MentionPageBlock);
      expect(mentionBlock, findsOneWidget);
      await tester.tapButton(mentionBlock);
    });

    testWidgets('insert a inline page and rename it', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      final pageName = await insertInlinePage(tester, ViewLayoutPB.Document);

      // rename
      const newName = 'RenameToNewPageName';
      await tester.hoverOnPageName(
        pageName,
        onHover: () async => tester.renamePage(newName),
      );
      final finder = find.descendant(
        of: find.byType(MentionPageBlock),
        matching: find.findTextInFlowyText(newName),
      );
      expect(finder, findsOneWidget);
    });

    testWidgets('insert a inline page and delete it', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      final pageName = await insertInlinePage(tester, ViewLayoutPB.Grid);

      // rename
      await tester.hoverOnPageName(
        pageName,
        layout: ViewLayoutPB.Grid,
        onHover: () async => tester.tapDeletePageButton(),
      );
      final finder = find.descendant(
        of: find.byType(MentionPageBlock),
        matching: find.findTextInFlowyText(pageName),
      );
      expect(finder, findsOneWidget);
      await tester.tapButton(finder);
      expect(find.byType(AppFlowyErrorPage), findsOneWidget);
    });
  });
}

/// Insert a referenced database of [layout] into the document
Future<String> insertInlinePage(
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
    name: 'insert_a_inline_page_${layout.name}',
  );

  // tap the first line of the document
  await tester.editor.tapLineOfEditorAt(0);

  // insert a inline page
  await tester.editor.showAtMenu();
  await tester.editor.tapAtMenuItemWithName(name);

  return name;
}
