import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/src/extensions/text_node_extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('update_text_style_by_command_x_handler.dart', () {
    testWidgets('Presses Command + B to update text style', (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.bold,
        LogicalKeyboardKey.keyB,
      );
    });
    testWidgets('Presses Command + I to update text style', (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.italic,
        LogicalKeyboardKey.keyI,
      );
    });
    testWidgets('Presses Command + U to update text style', (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.underline,
        LogicalKeyboardKey.keyU,
      );
    });
    testWidgets('Presses Command + S to update text style', (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.strikethrough,
        LogicalKeyboardKey.keyS,
      );
    });
  });
}

Future<void> _testUpdateTextStyleByCommandX(
    WidgetTester tester, String matchStyle, LogicalKeyboardKey key) async {
  const text = 'Welcome to Appflowy 😁';
  final editor = tester.editor
    ..insertTextNode(text)
    ..insertTextNode(text)
    ..insertTextNode(text);
  await editor.startTesting();

  var selection =
      Selection.single(path: [1], startOffset: 2, endOffset: text.length - 2);
  await editor.updateSelection(selection);
  await editor.pressLogicKey(
    key,
    isShiftPressed: key == LogicalKeyboardKey.keyS,
    isMetaPressed: true,
  );
  var textNode = editor.nodeAtPath([1]) as TextNode;
  expect(textNode.allSatisfyInSelection(matchStyle, selection), true);

  selection =
      Selection.single(path: [1], startOffset: 0, endOffset: text.length);
  await editor.updateSelection(selection);
  await editor.pressLogicKey(
    key,
    isShiftPressed: key == LogicalKeyboardKey.keyS,
    isMetaPressed: true,
  );
  textNode = editor.nodeAtPath([1]) as TextNode;
  expect(textNode.allSatisfyInSelection(matchStyle, selection), true);

  await editor.updateSelection(selection);
  await editor.pressLogicKey(
    key,
    isShiftPressed: key == LogicalKeyboardKey.keyS,
    isMetaPressed: true,
  );
  textNode = editor.nodeAtPath([1]) as TextNode;
  expect(textNode.allNotSatisfyInSelection(matchStyle, selection), true);

  selection = Selection(
    start: Position(path: [0], offset: 0),
    end: Position(path: [2], offset: text.length),
  );
  await editor.updateSelection(selection);
  await editor.pressLogicKey(
    key,
    isShiftPressed: key == LogicalKeyboardKey.keyS,
    isMetaPressed: true,
  );
  var nodes = editor.editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();
  expect(nodes.length, 3);
  for (final node in nodes) {
    expect(
      node.allSatisfyInSelection(
        matchStyle,
        Selection.single(
            path: node.path, startOffset: 0, endOffset: text.length),
      ),
      true,
    );
  }

  await editor.updateSelection(selection);
  await editor.pressLogicKey(
    key,
    isShiftPressed: key == LogicalKeyboardKey.keyS,
    isMetaPressed: true,
  );
  nodes = editor.editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();
  expect(nodes.length, 3);
  for (final node in nodes) {
    expect(
      node.allNotSatisfyInSelection(
        matchStyle,
        Selection.single(
            path: node.path, startOffset: 0, endOffset: text.length),
      ),
      true,
    );
  }
}
