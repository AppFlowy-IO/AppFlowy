import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('exit_editing_mode_handler.dart', () {
    testWidgets('Exit editing mode', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      const lines = 3;
      final editor = tester.editor;
      for (var i = 0; i < lines; i++) {
        editor.insertTextNode(text);
      }
      await editor.startTesting();

      // collaspsed selection
      await _testSelection(editor, Selection.single(path: [1], startOffset: 0));

      // single selection
      await _testSelection(
        editor,
        Selection.single(path: [1], startOffset: 0, endOffset: text.length),
      );

      // mutliple selection
      await _testSelection(
        editor,
        Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [2], offset: text.length),
        ),
      );
    });

    // Future<void> _testSelection()
  });
}

Future<void> _testSelection(
    EditorWidgetTester editor, Selection selection) async {
  await editor.updateSelection(selection);
  expect(editor.documentSelection, selection);
  await editor.pressLogicKey(LogicalKeyboardKey.escape);
  expect(editor.documentSelection, null);
}
