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

  testWidgets('Presses arrow left/right + shift in collapsed selection',
      (tester) async {
    const text = 'Welcome to Appflowy';
    final editor = tester.editor
      ..insertTextNode(text)
      ..insertTextNode(text);
    await editor.startTesting();
    const offset = 8;
    final selection = Selection.single(path: [1], startOffset: offset);
    await editor.updateSelection(selection);
    for (var i = offset - 1; i >= 0; i--) {
      await editor.pressLogicKey(
        LogicalKeyboardKey.arrowLeft,
        isShiftPressed: true,
      );
      expect(
        editor.documentSelection,
        selection.copyWith(
          end: Position(path: [1], offset: i),
        ),
      );
    }
    for (var i = text.length; i >= 0; i--) {
      await editor.pressLogicKey(
        LogicalKeyboardKey.arrowLeft,
        isShiftPressed: true,
      );
      expect(
        editor.documentSelection,
        selection.copyWith(
          end: Position(path: [0], offset: i),
        ),
      );
    }
    for (var i = 1; i <= text.length; i++) {
      await editor.pressLogicKey(
        LogicalKeyboardKey.arrowRight,
        isShiftPressed: true,
      );
      expect(
        editor.documentSelection,
        selection.copyWith(
          end: Position(path: [0], offset: i),
        ),
      );
    }
    for (var i = 0; i < text.length; i++) {
      await editor.pressLogicKey(
        LogicalKeyboardKey.arrowRight,
        isShiftPressed: true,
      );
      expect(
        editor.documentSelection,
        selection.copyWith(
          end: Position(path: [1], offset: i),
        ),
      );
    }
  });

  testWidgets(
      'Presses arrow left/right + shift in not collapsed and backward selection',
      (tester) async {
    const text = 'Welcome to Appflowy';
    final editor = tester.editor
      ..insertTextNode(text)
      ..insertTextNode(text);
    await editor.startTesting();
    const start = 8;
    const end = 12;
    final selection = Selection.single(
      path: [0],
      startOffset: start,
      endOffset: end,
    );
    await editor.updateSelection(selection);
    for (var i = end + 1; i <= text.length; i++) {
      await editor.pressLogicKey(
        LogicalKeyboardKey.arrowRight,
        isShiftPressed: true,
      );
      expect(
        editor.documentSelection,
        selection.copyWith(
          end: Position(path: [0], offset: i),
        ),
      );
    }
    for (var i = text.length - 1; i >= 0; i--) {
      await editor.pressLogicKey(
        LogicalKeyboardKey.arrowLeft,
        isShiftPressed: true,
      );
      expect(
        editor.documentSelection,
        selection.copyWith(
          end: Position(path: [0], offset: i),
        ),
      );
    }
  });

  testWidgets(
      'Presses arrow left/right + command in not collapsed and forward selection',
      (tester) async {
    const text = 'Welcome to Appflowy';
    final editor = tester.editor
      ..insertTextNode(text)
      ..insertTextNode(text);
    await editor.startTesting();
    const start = 12;
    const end = 8;
    final selection = Selection.single(
      path: [0],
      startOffset: start,
      endOffset: end,
    );
    await editor.updateSelection(selection);
    for (var i = end - 1; i >= 0; i--) {
      await editor.pressLogicKey(
        LogicalKeyboardKey.arrowLeft,
        isShiftPressed: true,
      );
      expect(
        editor.documentSelection,
        selection.copyWith(
          end: Position(path: [0], offset: i),
        ),
      );
    }
    for (var i = 1; i <= text.length; i++) {
      await editor.pressLogicKey(
        LogicalKeyboardKey.arrowRight,
        isShiftPressed: true,
      );
      expect(
        editor.documentSelection,
        selection.copyWith(
          end: Position(path: [0], offset: i),
        ),
      );
    }
  });

  testWidgets('Presses arrow left/right/up/down + meta in collapsed selection',
      (tester) async {
    await _testPressArrowKeyWithMetaInSelection(tester, true, false);
  });

  testWidgets(
      'Presses arrow left/right/up/down + meta in not collapsed and backward selection',
      (tester) async {
    await _testPressArrowKeyWithMetaInSelection(tester, false, true);
  });

  testWidgets(
      'Presses arrow left/right/up/down + meta in not collapsed and forward selection',
      (tester) async {
    await _testPressArrowKeyWithMetaInSelection(tester, false, false);
  });

  testWidgets('Presses arrow up/down + shift in not collapsed selection',
      (tester) async {
    const text = 'Welcome to Appflowy 😁';
    final editor = tester.editor
      ..insertTextNode(text)
      ..insertTextNode(text)
      ..insertTextNode(null)
      ..insertTextNode(text)
      ..insertTextNode(null)
      ..insertTextNode(text)
      ..insertTextNode(text);
    await editor.startTesting();
    final selection = Selection.single(path: [3], startOffset: 8);
    await editor.updateSelection(selection);
    for (int i = 0; i < 3; i++) {
      await editor.pressLogicKey(
        LogicalKeyboardKey.arrowUp,
        isShiftPressed: true,
      );
    }
    expect(
      editor.documentSelection,
      selection.copyWith(
        end: Position(path: [0], offset: 0),
      ),
    );
    for (int i = 0; i < 7; i++) {
      await editor.pressLogicKey(
        LogicalKeyboardKey.arrowDown,
        isShiftPressed: true,
      );
    }
    expect(
      editor.documentSelection,
      selection.copyWith(
        end: Position(path: [6], offset: 0),
      ),
    );
    for (int i = 0; i < 3; i++) {
      await editor.pressLogicKey(
        LogicalKeyboardKey.arrowUp,
        isShiftPressed: true,
      );
    }
    expect(
      editor.documentSelection,
      selection.copyWith(
        end: Position(path: [3], offset: 0),
      ),
    );
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

Future<void> _testPressArrowKeyWithMetaInSelection(
  WidgetTester tester,
  bool isSingle,
  bool isBackward,
) async {
  const text = 'Welcome to Appflowy';
  final editor = tester.editor
    ..insertTextNode(text)
    ..insertTextNode(text);
  await editor.startTesting();
  Selection selection;
  if (isSingle) {
    selection = Selection.single(
      path: [0],
      startOffset: 8,
    );
  } else {
    if (isBackward) {
      selection = Selection.single(
        path: [0],
        startOffset: 8,
        endOffset: text.length,
      );
    } else {
      selection = Selection.single(
        path: [0],
        startOffset: text.length,
        endOffset: 8,
      );
    }
  }
  await editor.updateSelection(selection);
  await editor.pressLogicKey(
    LogicalKeyboardKey.arrowLeft,
    isMetaPressed: true,
  );
  expect(
    editor.documentSelection,
    Selection.single(path: [0], startOffset: 0),
  );

  await editor.pressLogicKey(
    LogicalKeyboardKey.arrowRight,
    isMetaPressed: true,
  );
  expect(
    editor.documentSelection,
    Selection.single(path: [0], startOffset: text.length),
  );

  await editor.pressLogicKey(
    LogicalKeyboardKey.arrowUp,
    isMetaPressed: true,
  );
  expect(
    editor.documentSelection,
    Selection.single(path: [0], startOffset: 0),
  );

  await editor.pressLogicKey(
    LogicalKeyboardKey.arrowDown,
    isMetaPressed: true,
  );
  expect(
    editor.documentSelection,
    Selection.single(path: [1], startOffset: text.length),
  );
}
