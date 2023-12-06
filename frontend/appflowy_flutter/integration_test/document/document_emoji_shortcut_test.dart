import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_shortcut/emoji_shortcut_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/keyboard.dart';
import '../util/util.dart';

const arrowKeys = [
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowUp,
];

const scaredKeys = [
  LogicalKeyboardKey.keyS, // Scared
  LogicalKeyboardKey.keyC,
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyR,
  LogicalKeyboardKey.keyE,
  LogicalKeyboardKey.keyD,
];

const cloudsKeys = [
  LogicalKeyboardKey.keyC, // Cloud
  LogicalKeyboardKey.keyL,
  LogicalKeyboardKey.keyO,
  LogicalKeyboardKey.keyU,
  LogicalKeyboardKey.keyD,
  LogicalKeyboardKey.keyS,
];

const haloKeys = [
  LogicalKeyboardKey.keyH, // Halo
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyL,
  LogicalKeyboardKey.keyO,
];

const impKeys = [
  LogicalKeyboardKey.keyI, // Imp
  LogicalKeyboardKey.keyM,
  LogicalKeyboardKey.keyP,
];

const robotKeys = [
  LogicalKeyboardKey.keyR, // Robot
  LogicalKeyboardKey.keyO,
  LogicalKeyboardKey.keyB,
  LogicalKeyboardKey.keyO,
  LogicalKeyboardKey.keyT,
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
        impKeys.slice(0, robotKeys.length - 2),
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
  });
}

Future<void> insertEmoji(
  WidgetTester tester,
  String expected,
  List<LogicalKeyboardKey> emojiKeys,
  List<LogicalKeyboardKey> arrowKeys,
) async {
  await tester.initializeAppFlowy();
  await tester.tapGoButton();
  tester.expectToSeeHomePage();

  await tester.createNewPageWithName(
    //name: 'Test $emoji ${arrowKeys.isEmpty ? "" : " (keyboard) "}',
    layout: ViewLayoutPB.Document,
    openAfterCreated: true,
  );

  await tester.editor.tapLineOfEditorAt(0);

  // Determine whether the emoji picker hasn't been opened
  expect(find.byType(EmojiShortcutPickerView), findsNothing);

  // Press ':' to open the menu
  await tester.ime.insertText(':');

  // Determine whether the shortcut works and the emoji picker is opened
  expect(find.byType(EmojiShortcutPickerView), findsOneWidget);

  // Type emoji text
  await FlowyTestKeyboard.simulateKeyDownEvent(tester: tester, emojiKeys);

  // Perform arrow keyboard combination eg: [RIGHT, DOWN, LEFT, UP]
  if (arrowKeys.isNotEmpty) {
    await FlowyTestKeyboard.simulateKeyDownEvent(tester: tester, arrowKeys);
  }

  //await tester.pumpAndSettle();

  // Press ENTER to insert the emoji and replace text
  await FlowyTestKeyboard.simulateKeyDownEvent(
    tester: tester,
    [LogicalKeyboardKey.enter],
  );
  //await tester.simulateKeyEvent(LogicalKeyboardKey.enter);

  // Check if typed text is replaced by emoji
  expect(
    tester.editor.getCurrentEditorState().document.last!.delta!.toPlainText(),
    expected,
  );

  // Determine whether the emoji picker is closed on enter
  expect(find.byType(EmojiShortcutPickerView), findsNothing);
}
