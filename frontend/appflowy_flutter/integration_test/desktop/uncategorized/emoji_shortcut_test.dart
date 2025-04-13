import 'dart:io';

import 'package:appflowy/plugins/emoji/emoji_handler.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/keyboard.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // May be better to move this to an existing test but unsure what it fits with
  group('Keyboard shortcuts related to emojis', () {
    testWidgets('cmd/ctrl+alt+e shortcut opens the emoji picker',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      final Finder editor = find.byType(AppFlowyEditor);
      await tester.tap(editor);
      await tester.pumpAndSettle();

      expect(find.byType(EmojiSelectionMenu), findsNothing);

      await FlowyTestKeyboard.simulateKeyDownEvent(
        [
          Platform.isMacOS
              ? LogicalKeyboardKey.meta
              : LogicalKeyboardKey.control,
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.keyE,
        ],
        tester: tester,
      );

      expect(find.byType(EmojiSelectionMenu), findsOneWidget);
    });
  });

  group('insert emoji by colon', () {
    Future<void> createNewDocumentAndShowEmojiList(
      WidgetTester tester, {
      String? search,
    }) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.createNewPageWithNameUnderParent();
      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText(':${search ?? 'a'}');
      await tester.pumpAndSettle(Duration(seconds: 1));
    }

    testWidgets('insert with click', (tester) async {
      await createNewDocumentAndShowEmojiList(tester);

      /// emoji list is showing
      final emojiHandler = find.byType(EmojiHandler);
      expect(emojiHandler, findsOneWidget);
      final emojiButtons =
          find.descendant(of: emojiHandler, matching: find.byType(FlowyButton));
      final firstTextFinder = find.descendant(
        of: emojiButtons.first,
        matching: find.byType(FlowyText),
      );
      final emojiText =
          (firstTextFinder.evaluate().first.widget as FlowyText).text;

      /// click first emoji item
      await tester.tapButton(emojiButtons.first);
      final firstNode =
          tester.editor.getCurrentEditorState().getNodeAtPath([0])!;

      /// except the emoji is in document
      expect(emojiText.contains(firstNode.delta!.toPlainText()), true);
    });

    testWidgets('insert with arrow and enter', (tester) async {
      await createNewDocumentAndShowEmojiList(tester);

      /// emoji list is showing
      final emojiHandler = find.byType(EmojiHandler);
      expect(emojiHandler, findsOneWidget);
      final emojiButtons =
          find.descendant(of: emojiHandler, matching: find.byType(FlowyButton));

      /// tap arrow down and arrow up
      await tester.simulateKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.simulateKeyEvent(LogicalKeyboardKey.arrowDown);

      final firstTextFinder = find.descendant(
        of: emojiButtons.first,
        matching: find.byType(FlowyText),
      );
      final emojiText =
          (firstTextFinder.evaluate().first.widget as FlowyText).text;

      /// tap enter
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      final firstNode =
          tester.editor.getCurrentEditorState().getNodeAtPath([0])!;

      /// except the emoji is in document
      expect(emojiText.contains(firstNode.delta!.toPlainText()), true);
    });

    testWidgets('insert with searching', (tester) async {
      await createNewDocumentAndShowEmojiList(tester, search: 's');

      /// search for `smiling eyes`, IME is not working, use keyboard input
      final searchText = [
        LogicalKeyboardKey.keyM,
        LogicalKeyboardKey.keyI,
        LogicalKeyboardKey.keyL,
        LogicalKeyboardKey.keyI,
        LogicalKeyboardKey.keyN,
        LogicalKeyboardKey.keyG,
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyY,
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyS,
      ];

      for (final key in searchText) {
        await tester.simulateKeyEvent(key);
      }

      /// tap enter
      await tester.simulateKeyEvent(LogicalKeyboardKey.enter);
      final firstNode =
          tester.editor.getCurrentEditorState().getNodeAtPath([0])!;

      /// except the emoji is in document
      expect(firstNode.delta!.toPlainText().contains('😄'), true);
    });

    testWidgets('start searching with sapce', (tester) async {
      await createNewDocumentAndShowEmojiList(tester, search: ' ');

      /// emoji list is showing
      final emojiHandler = find.byType(EmojiHandler);
      expect(emojiHandler, findsNothing);
    });
  });
}
