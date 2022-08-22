import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('redo_undo_handler_test.dart', () {
    // TODO: need to test more cases.
    testWidgets('Redo, Undo for backspace key, and selection is downward',
        (tester) async {
      await _testBackspaceUndoRedo(tester, true);
    });

    testWidgets('Redo, Undo for backspace key, and selection is forward',
        (tester) async {
      await _testBackspaceUndoRedo(tester, false);
    });
  });
}

Future<void> _testBackspaceUndoRedo(
    WidgetTester tester, bool isDownwardSelection) async {
  const text = 'Welcome to Appflowy 😁';
  final editor = tester.editor
    ..insertTextNode(text)
    ..insertTextNode(text)
    ..insertTextNode(text);
  await editor.startTesting();

  final start = Position(path: [0], offset: text.length);
  final end = Position(path: [1], offset: text.length);
  final selection = Selection(
    start: isDownwardSelection ? start : end,
    end: isDownwardSelection ? end : start,
  );
  await editor.updateSelection(selection);
  await editor.pressLogicKey(LogicalKeyboardKey.backspace);
  expect(editor.documentLength, 2);

  await editor.pressLogicKey(
    LogicalKeyboardKey.keyZ,
    isMetaPressed: true,
  );

  expect(editor.documentLength, 3);
  expect((editor.nodeAtPath([1]) as TextNode).toRawString(), text);
  expect(editor.documentSelection, selection);

  await editor.pressLogicKey(
    LogicalKeyboardKey.keyZ,
    isMetaPressed: true,
    isShiftPressed: true,
  );

  expect(editor.documentLength, 2);
}
