import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('arrow_keys_handler.dart', () {
    testWidgets('Presses arrow right key, move the cursor from left to right',
        (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();

      await editor.updateSelection(
        Selection.single(path: [0], startOffset: 0),
      );

      final textNode = editor.nodeAtPath([0]) as TextNode;
      for (var i = 0; i < text.length; i++) {
        await editor.pressLogicKey(LogicalKeyboardKey.arrowRight);

        if (i == text.length - 1) {
          // Wrap to next node if the cursor is at the end of the current node.
          expect(
            editor.documentSelection,
            Selection.single(
              path: [1],
              startOffset: 0,
            ),
          );
        } else {
          expect(
            editor.documentSelection,
            Selection.single(
              path: [0],
              startOffset: textNode.delta.nextRunePosition(i),
            ),
          );
        }
      }
    });
  });

  testWidgets(
      'Presses arrow left/right key since selection is not collapsed and backward',
      (tester) async {
    await _testPressArrowKeyInNotCollapsedSelection(tester, true);
  });

  testWidgets(
      'Presses arrow left/right key since selection is not collapsed and forward',
      (tester) async {
    await _testPressArrowKeyInNotCollapsedSelection(tester, false);
  });
}

Future<void> _testPressArrowKeyInNotCollapsedSelection(
    WidgetTester tester, bool isBackward) async {
  const text = 'Welcome to Appflowy 😁';
  final editor = tester.editor
    ..insertTextNode(text)
    ..insertTextNode(text);
  await editor.startTesting();

  final start = Position(path: [0], offset: 5);
  final end = Position(path: [1], offset: 10);
  final selection = Selection(
    start: isBackward ? start : end,
    end: isBackward ? end : start,
  );
  await editor.updateSelection(selection);
  await editor.pressLogicKey(LogicalKeyboardKey.arrowLeft);
  expect(editor.documentSelection?.start, start);

  await editor.updateSelection(selection);
  await editor.pressLogicKey(LogicalKeyboardKey.arrowRight);
  expect(editor.documentSelection?.end, end);
}
