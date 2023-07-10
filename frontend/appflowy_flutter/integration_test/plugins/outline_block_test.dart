import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/outline/outline_block_component.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/ime.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('outline block test', () {
    testWidgets('insert an outline block', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(
        ViewLayoutPB.Document,
        'outline_test',
      );

      await tester.editor.tapLineOfEditorAt(0);
      await insertOutlineInDocument(tester);

      // validate the outline is inserted
      expect(find.byType(OutlineBlockWidget), findsOneWidget);
    });

    testWidgets('insert an outline block and check if headings are visible',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(
        ViewLayoutPB.Document,
        'outline_test',
      );
      await tester.editor.tapLineOfEditorAt(0);

      await tester.ime.insertText('# Heading 1\n');
      await tester.ime.insertText('## Heading 2\n');
      await tester.ime.insertText('### Heading 3\n');

      /* Results in:
      * # Heading 1
      * ## Heading 2
      * ### Heading 3
      */

      await tester.editor.tapLineOfEditorAt(3);
      await insertOutlineInDocument(tester);

      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text('Heading 1'),
        ),
        findsOneWidget,
      );

      // Heading 2 is prefixed with a bullet
      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text('Heading 2'),
        ),
        findsOneWidget,
      );

      // Heading 3 is prefixed with a dash
      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text('Heading 3'),
        ),
        findsOneWidget,
      );

      // update the Heading 1 to Heading 1Hello world
      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText('Hello world');
      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text('Heading 1Hello world'),
        ),
        findsOneWidget,
      );
    });
  });
}

/// Inserts an outline block in the document
Future<void> insertOutlineInDocument(WidgetTester tester) async {
  // open the actions menu and insert the outline block
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName(
    LocaleKeys.document_selectionMenu_outline.tr(),
  );
  await tester.pumpAndSettle();
}
