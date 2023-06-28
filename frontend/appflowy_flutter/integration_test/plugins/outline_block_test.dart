import 'package:appflowy/plugins/document/presentation/editor_plugins/outline/outline_block_component.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/ime.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('outline block test', () {
    const location = 'outline_test';

    setUp(() async {
      await TestFolder.cleanTestLocation(location);
      await TestFolder.setTestLocation(location);
    });

    tearDown(() async {
      await TestFolder.cleanTestLocation(null);
    });

    testWidgets('insert an outline', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(ViewLayoutPB.Document, "outline_test");

      await insertOutlineInDocument(tester);

      // validate the outline is inserted
      expect(find.byType(OutlineBlockWidget), findsOneWidget);
    });

    testWidgets('insert an outline and check if headings are visible',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(ViewLayoutPB.Document, "outline_test");
      await tester.editor.tapLineOfEditorAt(0);

      await tester.ime.insertText("\n# Heading 1");
      await tester.ime.insertText("\n## Heading 2");
      await tester.ime.insertText("\n### Heading 3");

      /* Results in:
      * 0.  
      * 1. # Heading 1
      * 2. ## Heading 2
      * 3. ### Heading 3
      */

      await insertOutlineInDocument(tester);

      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text("Heading 1"),
        ),
        findsOneWidget,
      );

      // Heading 2 is prefixed with a bullet
      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text("∘ Heading 2"),
        ),
        findsOneWidget,
      );

      // Heading 3 is prefixed with a dash
      expect(
        find.descendant(
          of: find.byType(OutlineBlockWidget),
          matching: find.text("- Heading 3"),
        ),
        findsOneWidget,
      );
    });
  });
}

/// Inserts an outline block in the document
Future<void> insertOutlineInDocument(WidgetTester tester) async {
  await tester.editor.tapLineOfEditorAt(0);

  // open the actions menu and insert the outline block
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName("Outline");
}
