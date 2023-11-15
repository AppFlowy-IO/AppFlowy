import 'package:appflowy/plugins/document/presentation/editor_plugins/base/link_to_page_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/keyboard.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('insert inline document reference', () {
    testWidgets('insert by slash menu', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      final name = await createDocumentToReference(tester);

      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();

      await triggerReferenceDocumentBySlashMenu(tester);

      // Search for prefix of document
      await enterDocumentText(tester);

      // Select result
      final optionFinder = find.descendant(
        of: find.byType(LinkToPageMenu),
        matching: find.text(name),
      );

      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      final mentionBlock = find.byType(MentionPageBlock);
      expect(mentionBlock, findsOneWidget);
    });

    testWidgets('insert by `[[` character shortcut', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      final name = await createDocumentToReference(tester);

      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();

      await tester.ime.insertText('[[');
      await tester.pumpAndSettle();

      // Select result
      await tester.editor.tapAtMenuItemWithName(name);
      await tester.pumpAndSettle();

      final mentionBlock = find.byType(MentionPageBlock);
      expect(mentionBlock, findsOneWidget);
    });

    testWidgets('insert by `+` character shortcut', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      final name = await createDocumentToReference(tester);

      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();

      await tester.ime.insertText('+');
      await tester.pumpAndSettle();

      // Select result
      await tester.editor.tapAtMenuItemWithName(name);
      await tester.pumpAndSettle();

      final mentionBlock = find.byType(MentionPageBlock);
      expect(mentionBlock, findsOneWidget);
    });
  });
}

Future<String> createDocumentToReference(WidgetTester tester) async {
  final name = 'document_${uuid()}';

  await tester.createNewPageWithName(
    name: name,
    layout: ViewLayoutPB.Document,
    openAfterCreated: false,
  );

  // This is a workaround since the openAfterCreated
  //  option does not work in createNewPageWithName method
  await tester.tap(find.byType(SingleInnerViewItem).first);
  await tester.pumpAndSettle();

  return name;
}

Future<void> triggerReferenceDocumentBySlashMenu(WidgetTester tester) async {
  await tester.editor.showSlashMenu();
  await tester.pumpAndSettle();

  // Search for referenced document action
  await enterDocumentText(tester);

  // Select item
  await FlowyTestKeyboard.simulateKeyDownEvent(
    [
      LogicalKeyboardKey.enter,
    ],
    tester: tester,
  );

  await tester.pumpAndSettle();
}

Future<void> enterDocumentText(WidgetTester tester) async {
  await FlowyTestKeyboard.simulateKeyDownEvent(
    [
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyC,
      LogicalKeyboardKey.keyU,
      LogicalKeyboardKey.keyM,
      LogicalKeyboardKey.keyE,
      LogicalKeyboardKey.keyN,
      LogicalKeyboardKey.keyT,
    ],
    tester: tester,
  );
  await tester.pumpAndSettle();
}
