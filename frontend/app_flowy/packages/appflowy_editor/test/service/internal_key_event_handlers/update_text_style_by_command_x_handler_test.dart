import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/extensions/text_node_extensions.dart';
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
        true,
        LogicalKeyboardKey.keyB,
      );
    });
    testWidgets('Presses Command + I to update text style', (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.italic,
        true,
        LogicalKeyboardKey.keyI,
      );
    });
    testWidgets('Presses Command + U to update text style', (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.underline,
        true,
        LogicalKeyboardKey.keyU,
      );
    });
    testWidgets('Presses Command + Shift + S to update text style',
        (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.strikethrough,
        true,
        LogicalKeyboardKey.keyS,
      );
    });

    testWidgets('Presses Command + Shift + H to update text style',
        (tester) async {
      await _testUpdateTextStyleByCommandX(
        tester,
        StyleKey.backgroundColor,
        defaultHighlightColor,
        LogicalKeyboardKey.keyH,
      );
    });
  });
}

Future<void> _testUpdateTextStyleByCommandX(
  WidgetTester tester,
  String matchStyle,
  dynamic matchValue,
  LogicalKeyboardKey key,
) async {
  final isShiftPressed =
      key == LogicalKeyboardKey.keyS || key == LogicalKeyboardKey.keyH;
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
    isShiftPressed: isShiftPressed,
    isMetaPressed: true,
  );
  var textNode = editor.nodeAtPath([1]) as TextNode;
  expect(
      textNode.allSatisfyInSelection(
        matchStyle,
        selection,
        (value) {
          return value == matchValue;
        },
      ),
      true);

  selection =
      Selection.single(path: [1], startOffset: 0, endOffset: text.length);
  await editor.updateSelection(selection);
  await editor.pressLogicKey(
    key,
    isShiftPressed: isShiftPressed,
    isMetaPressed: true,
  );
  textNode = editor.nodeAtPath([1]) as TextNode;
  expect(
      textNode.allSatisfyInSelection(
        matchStyle,
        selection,
        (value) {
          return value == matchValue;
        },
      ),
      true);

  await editor.updateSelection(selection);
  await editor.pressLogicKey(
    key,
    isShiftPressed: isShiftPressed,
    isMetaPressed: true,
  );
  textNode = editor.nodeAtPath([1]) as TextNode;
  expect(textNode.allNotSatisfyInSelection(matchStyle, matchValue, selection),
      true);

  selection = Selection(
    start: Position(path: [0], offset: 0),
    end: Position(path: [2], offset: text.length),
  );
  await editor.updateSelection(selection);
  await editor.pressLogicKey(
    key,
    isShiftPressed: isShiftPressed,
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
          path: node.path,
          startOffset: 0,
          endOffset: text.length,
        ),
        (value) {
          return value == matchValue;
        },
      ),
      true,
    );
  }

  await editor.updateSelection(selection);
  await editor.pressLogicKey(
    key,
    isShiftPressed: isShiftPressed,
    isMetaPressed: true,
  );
  nodes = editor.editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();
  expect(nodes.length, 3);
  for (final node in nodes) {
    expect(
      node.allNotSatisfyInSelection(
        matchStyle,
        matchValue,
        Selection.single(
            path: node.path, startOffset: 0, endOffset: text.length),
      ),
      true,
    );
  }
}
