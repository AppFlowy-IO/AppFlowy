import 'package:flutter/services.dart';

import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_shortcut/emoji_shortcut_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/keyboard.dart';
import '../../shared/util.dart';

const arrowKeys = [
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowUp,
];

// Keyboard keys to type "halo"
const haloKeys = [
  LogicalKeyboardKey.keyH,
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyL,
  LogicalKeyboardKey.keyO,
];

// Keyboard keys to type "imp"
const impKeys = [
  LogicalKeyboardKey.keyI,
  LogicalKeyboardKey.keyM,
  LogicalKeyboardKey.keyP,
];

// Keyboard keys to type "robot"
const robotKeys = [
  LogicalKeyboardKey.keyR,
  LogicalKeyboardKey.keyO,
  LogicalKeyboardKey.keyB,
  LogicalKeyboardKey.keyO,
  LogicalKeyboardKey.keyT,
];

// Keyboard keys to type "kenya"
const kenyaKeys = [
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.keyK,
  LogicalKeyboardKey.keyE,
  LogicalKeyboardKey.keyN,
  LogicalKeyboardKey.keyY,
  LogicalKeyboardKey.keyA,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Insert Emoji', () {
    testWidgets('smiling face with halo', (tester) async {
      await insertEmoji(tester, '😇', haloKeys, []);
    });

    testWidgets('imp', (tester) async {
      await insertEmoji(tester, '🦐', impKeys, []);
    });

    testWidgets('robot', (tester) async {
      await insertEmoji(tester, '🤖', robotKeys, []);
    });

    testWidgets('kenya', (tester) async {
      await insertEmoji(tester, '🇰🇪', kenyaKeys, []);
    });
  });

  group('Insert Emoji using arrow keys', () {
    testWidgets('smiling face with halo via arrow keys', (tester) async {
      await insertEmoji(
        tester,
        '😇',
        haloKeys.slice(0, haloKeys.length - 2),
        arrowKeys,
      );
    });

    testWidgets('imp via arrow keys', (tester) async {
      await insertEmoji(
        tester,
        '🦐',
        impKeys.slice(0, impKeys.length - 1),
        arrowKeys,
      );
    });

    testWidgets('robot via arrow keys', (tester) async {
      await insertEmoji(
        tester,
        '🤖',
        robotKeys.slice(0, robotKeys.length - 2),
        arrowKeys,
      );
    });

    testWidgets('kenya via arrow keys', (tester) async {
      await insertEmoji(
        tester,
        '🇰🇪',
        kenyaKeys.slice(0, robotKeys.length - 2),
        arrowKeys,
      );
    });
  });
}

Future<void> insertEmoji(
  WidgetTester tester,
  String expected,
  List<LogicalKeyboardKey> emojiKeys,
  List<LogicalKeyboardKey> arrowKeys,
) async {
  await tester.initializeAppFlowy();
  await tester.tapAnonymousSignInButton();

  await tester.expectToSeeHomePage();

  await tester.createNewPageWithNameUnderParent(
    name: 'Test $expected ${arrowKeys.isEmpty ? "" : " (keyboard) "}',
  );

  await tester.editor.tapLineOfEditorAt(0);

  // Determine whether the emoji picker hasn't been opened
  expect(find.byType(EmojiShortcutPickerView), findsNothing);

  // Press ':' to open the menu
  await tester.ime.insertText(':');

  // Determine whether the shortcut works and the emoji picker is opened
  expect(find.byType(EmojiShortcutPickerView), findsOneWidget);

  // Perform specific keyboard events to find and insert emoji
  await FlowyTestKeyboard.simulateKeyDownEvent(
    tester: tester,
    withKeyUp: true,
    [
      // Type emoji text
      ...emojiKeys,

      // Press arrow keyboard combination eg: [RIGHT, DOWN, LEFT, UP]
      ...arrowKeys,

      // Press ENTER to insert the emoji and replace text
      LogicalKeyboardKey.enter,
    ],
  );

  // Check if typed text is replaced by emoji
  expect(
    tester.editor.getCurrentEditorState().document.last!.delta!.toPlainText(),
    expected,
  );

  // Determine whether the emoji picker is closed
  expect(find.byType(EmojiShortcutPickerView), findsNothing);
}
