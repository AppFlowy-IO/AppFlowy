import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/plugins/inline_actions/widgets/inline_actions_handler.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/keyboard.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('insert inline document reference', () {
    testWidgets('insert by slash menu', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      final name = await createDocumentToReference(tester);

      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();

      await triggerReferenceDocumentBySlashMenu(tester);

      // Search for prefix of document
      await enterDocumentText(tester);

      // Select result
      final optionFinder = find.descendant(
        of: find.byType(InlineActionsHandler),
        matching: find.text(name),
      );

      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      final mentionBlock = find.byType(MentionPageBlock);
      expect(mentionBlock, findsOneWidget);
    });

    testWidgets('insert by `[[` character shortcut', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

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
      await tester.tapAnonymousSignInButton();

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

  await tester.createNewPageWithNameUnderParent(
    name: name,
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
    withKeyUp: true,
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
    withKeyUp: true,
  );
  await tester.pumpAndSettle();
}
