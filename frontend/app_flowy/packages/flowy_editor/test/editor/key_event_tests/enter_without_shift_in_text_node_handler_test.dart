import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('enter_without_shift_in_text_node_handler.dart', () {
    testWidgets('Presses enter key in empty document', (tester) async {
      final editor = tester.editor..insertEmptyTextNode();
      await editor.startTesting();
      await editor.updateSelection(
        Selection.collapsed(
          Position(path: [0], offset: 0),
        ),
      );
      // Pressing the enter key continuously.
      for (int i = 1; i <= 10; i++) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.enter,
        );
        expect(editor.documentLength, i + 1);
        expect(editor.documentSelection,
            Selection.collapsed(Position(path: [i], offset: 0)));
      }
    });

    testWidgets('Presses enter key in non-empty document', (tester) async {
      // Before
      //
      // Welcome to Appflowy 😁
      // Welcome to Appflowy 😁
      // Welcome to Appflowy 😁
      //
      // After
      //
      // Welcome to Appflowy 😁
      // Welcome to Appflowy 😁
      // [Empty Line]
      // Welcome to Appflowy 😁
      //
      const text = 'Welcome to Appflowy 😁';
      var lines = 3;

      final editor = tester.editor;
      for (var i = 1; i <= lines; i++) {
        editor.insertTextNode(text);
      }
      await editor.startTesting();

      expect(editor.documentLength, lines);

      // Presses the enter key in last line.
      await editor.updateSelection(
        Selection.collapsed(
          Position(path: [lines - 1], offset: 0),
        ),
      );
      await editor.pressLogicKey(
        LogicalKeyboardKey.enter,
      );
      lines += 1;
      expect(editor.documentLength, lines);
      expect(editor.documentSelection,
          Selection.collapsed(Position(path: [lines - 1], offset: 0)));
      var lastNode = editor.nodeAtPath([lines - 1]);
      expect(lastNode != null, true);
      expect(lastNode is TextNode, true);
      lastNode = lastNode as TextNode;
      for (final node in editor.root.children) {
        print(
            'path = ${node.path}, text = ${(node as TextNode).toRawString()}');
      }
      expect(lastNode.delta.toRawString(), text);
      expect((lastNode.previous as TextNode).delta.toRawString(), '');
      expect(
          (lastNode.previous!.previous as TextNode).delta.toRawString(), text);
    });

    // Before
    //
    // Welcome to Appflowy 😁
    // [Style] Welcome to Appflowy 😁
    // [Style] Welcome to Appflowy 😁
    //
    // After
    //
    // Welcome to Appflowy 😁
    // [Empty Line]
    // [Style] Welcome to Appflowy 😁
    // [Style] Welcome to Appflowy 😁
    // [Style]
    testWidgets('Presses enter key in bulleted list', (tester) async {
      await _testStyleNeedToBeCopy(tester, StyleKey.bulletedList);
    });
    testWidgets('Presses enter key in numbered list', (tester) async {
      await _testStyleNeedToBeCopy(tester, StyleKey.numberList);
    });
    testWidgets('Presses enter key in checkbox styled text', (tester) async {
      await _testStyleNeedToBeCopy(tester, StyleKey.checkbox);
    });
    testWidgets('Presses enter key in quoted text', (tester) async {
      await _testStyleNeedToBeCopy(tester, StyleKey.quote);
    });
  });
}

Future<void> _testStyleNeedToBeCopy(WidgetTester tester, String style) async {
  const text = 'Welcome to Appflowy 😁';
  Attributes attributes = {
    StyleKey.subtype: style,
  };
  if (style == StyleKey.checkbox) {
    attributes[StyleKey.checkbox] = false;
  } else if (style == StyleKey.numberList) {
    attributes[StyleKey.number] = 1;
  }
  final editor = tester.editor
    ..insertTextNode(text)
    ..insertTextNode(text, attributes: attributes)
    ..insertTextNode(text, attributes: attributes);

  await editor.startTesting();
  await editor.updateSelection(
    Selection.collapsed(
      Position(path: [1], offset: 0),
    ),
  );
  await editor.pressLogicKey(
    LogicalKeyboardKey.enter,
  );
  expect(editor.documentSelection,
      Selection.collapsed(Position(path: [2], offset: 0)));

  await editor.updateSelection(
    Selection.collapsed(
      Position(path: [3], offset: text.length),
    ),
  );
  await editor.pressLogicKey(
    LogicalKeyboardKey.enter,
  );
  expect(editor.documentSelection,
      Selection.collapsed(Position(path: [4], offset: 0)));
  expect(editor.nodeAtPath([4])?.subtype, style);

  await editor.pressLogicKey(
    LogicalKeyboardKey.enter,
  );
  expect(editor.documentSelection,
      Selection.collapsed(Position(path: [4], offset: 0)));
  expect(editor.nodeAtPath([4])?.subtype, null);
}
