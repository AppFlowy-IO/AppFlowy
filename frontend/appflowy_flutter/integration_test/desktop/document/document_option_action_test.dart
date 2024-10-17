import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/callout/callout_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // +, ... button beside the block component.
  group('block option action:', () {
    Future<void> turnIntoBlock(
      WidgetTester tester,
      Path path, {
      required String menuText,
      required String afterType,
    }) async {
      await tester.editor.openTurnIntoMenu(path);
      await tester.tapButton(
        find.findTextInFlowyText(menuText),
      );
      final node = tester.editor.getCurrentEditorState().getNodeAtPath(path);
      expect(node?.type, afterType);
    }

    testWidgets('''click + to add a block after current selection,
         and click + and option key to add a block before current selection''',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      var editorState = tester.editor.getCurrentEditorState();
      expect(editorState.getNodeAtPath([1])?.delta?.toPlainText(), isNotEmpty);

      // add a new block after the current selection
      await tester.editor.hoverAndClickOptionAddButton([0], false);
      // await tester.pumpAndSettle();
      expect(editorState.getNodeAtPath([1])?.delta?.toPlainText(), isEmpty);

      // cancel the selection menu
      await tester.tapAt(Offset.zero);

      await tester.editor.hoverAndClickOptionAddButton([0], true);
      await tester.pumpAndSettle();
      expect(editorState.getNodeAtPath([0])?.delta?.toPlainText(), isEmpty);
      // cancel the selection menu
      await tester.tapAt(Offset.zero);
      await tester.tapAt(Offset.zero);

      await tester.createNewPageWithNameUnderParent(name: 'test');
      await tester.openPage(gettingStarted);

      // check the status again
      editorState = tester.editor.getCurrentEditorState();
      expect(editorState.getNodeAtPath([0])?.delta?.toPlainText(), isEmpty);
      expect(editorState.getNodeAtPath([2])?.delta?.toPlainText(), isEmpty);
    });

    testWidgets('turn into - single line', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      const name = 'Test Document';
      await tester.createNewPageWithNameUnderParent(name: name);
      await tester.openPage(name);

      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText('turn into');

      // click the block option button to convert it to another blocks
      final values = {
        LocaleKeys.document_slashMenu_name_heading1.tr(): HeadingBlockKeys.type,
        LocaleKeys.document_slashMenu_name_heading2.tr(): HeadingBlockKeys.type,
        LocaleKeys.document_slashMenu_name_heading3.tr(): HeadingBlockKeys.type,
        LocaleKeys.document_slashMenu_name_bulletedList.tr():
            BulletedListBlockKeys.type,
        LocaleKeys.document_slashMenu_name_numberedList.tr():
            NumberedListBlockKeys.type,
        LocaleKeys.document_slashMenu_name_quote.tr(): QuoteBlockKeys.type,
        LocaleKeys.document_slashMenu_name_todoList.tr():
            TodoListBlockKeys.type,
        LocaleKeys.document_slashMenu_name_callout.tr(): CalloutBlockKeys.type,
        LocaleKeys.document_slashMenu_name_text.tr(): ParagraphBlockKeys.type,
      };

      for (final value in values.entries) {
        final menuText = value.key;
        final afterType = value.value;
        await turnIntoBlock(
          tester,
          [0],
          menuText: menuText,
          afterType: afterType,
        );
      }
    });

    testWidgets('turn into - multi lines', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      const name = 'Test Document';
      await tester.createNewPageWithNameUnderParent(name: name);
      await tester.openPage(name);

      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText('turn into 1');
      await tester.ime.insertCharacter('\n');
      await tester.ime.insertText('turn into 2');

      // click the block option button to convert it to another blocks
      final values = {
        LocaleKeys.document_slashMenu_name_heading1.tr(): HeadingBlockKeys.type,
        LocaleKeys.document_slashMenu_name_heading2.tr(): HeadingBlockKeys.type,
        LocaleKeys.document_slashMenu_name_heading3.tr(): HeadingBlockKeys.type,
        LocaleKeys.document_slashMenu_name_bulletedList.tr():
            BulletedListBlockKeys.type,
        LocaleKeys.document_slashMenu_name_numberedList.tr():
            NumberedListBlockKeys.type,
        LocaleKeys.document_slashMenu_name_quote.tr(): QuoteBlockKeys.type,
        LocaleKeys.document_slashMenu_name_todoList.tr():
            TodoListBlockKeys.type,
        LocaleKeys.document_slashMenu_name_callout.tr(): CalloutBlockKeys.type,
        LocaleKeys.document_slashMenu_name_text.tr(): ParagraphBlockKeys.type,
      };

      for (final value in values.entries) {
        final editorState = tester.editor.getCurrentEditorState();
        editorState.selection = Selection(
          start: Position(path: [0]),
          end: Position(path: [1], offset: 2),
        );
        final menuText = value.key;
        final afterType = value.value;
        await turnIntoBlock(
          tester,
          [0],
          menuText: menuText,
          afterType: afterType,
        );
      }
    });
  });
}
