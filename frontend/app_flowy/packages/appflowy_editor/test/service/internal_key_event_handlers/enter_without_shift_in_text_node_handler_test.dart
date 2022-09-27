import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('enter_without_shift_in_text_node_handler.dart', () {
    testWidgets('Presses enter key in empty document', (tester) async {
      // Before
      //
      // [Empty Line]
      //
      // After
      //
      // [Empty Line] * 10
      //
      final editor = tester.editor..insertEmptyTextNode();
      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [0], startOffset: 0),
      );
      // Pressing the enter key continuously.
      for (int i = 1; i <= 10; i++) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.enter,
        );
        expect(editor.documentLength, i + 1);
        expect(editor.documentSelection,
            Selection.single(path: [i], startOffset: 0));
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
        Selection.single(path: [lines - 1], startOffset: 0),
      );
      await editor.pressLogicKey(
        LogicalKeyboardKey.enter,
      );
      lines += 1;
      expect(editor.documentLength, lines);
      expect(editor.documentSelection,
          Selection.single(path: [lines - 1], startOffset: 0));
      var lastNode = editor.nodeAtPath([lines - 1]);
      expect(lastNode != null, true);
      expect(lastNode is TextNode, true);
      lastNode = lastNode as TextNode;
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
      await _testStyleNeedToBeCopy(tester, BuiltInAttributeKey.bulletedList);
    });
    testWidgets('Presses enter key in numbered list', (tester) async {
      await _testStyleNeedToBeCopy(tester, BuiltInAttributeKey.numberList);
    });
    testWidgets('Presses enter key in checkbox styled text', (tester) async {
      await _testStyleNeedToBeCopy(tester, BuiltInAttributeKey.checkbox);
    });
    testWidgets('Presses enter key in quoted text', (tester) async {
      await _testStyleNeedToBeCopy(tester, BuiltInAttributeKey.quote);
    });

    testWidgets('Presses enter key in multiple selection from top to bottom',
        (tester) async {
      _testMultipleSelection(tester, true);
    });

    testWidgets('Presses enter key in multiple selection from bottom to top',
        (tester) async {
      _testMultipleSelection(tester, false);
    });

    testWidgets('Presses enter key in the first line', (tester) async {
      // Before
      //
      // Welcome to Appflowy 😁
      //
      // After
      //
      // [Empty Line]
      // Welcome to Appflowy 😁
      //
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor..insertTextNode(text);
      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [0], startOffset: 0),
      );
      await editor.pressLogicKey(LogicalKeyboardKey.enter);
      expect(editor.documentLength, 2);
      expect((editor.nodeAtPath([1]) as TextNode).toRawString(), text);
    });
  });
}

Future<void> _testStyleNeedToBeCopy(WidgetTester tester, String style) async {
  const text = 'Welcome to Appflowy 😁';
  Attributes attributes = {
    BuiltInAttributeKey.subtype: style,
  };
  if (style == BuiltInAttributeKey.checkbox) {
    attributes[BuiltInAttributeKey.checkbox] = true;
  } else if (style == BuiltInAttributeKey.numberList) {
    attributes[BuiltInAttributeKey.number] = 1;
  }
  final editor = tester.editor
    ..insertTextNode(text)
    ..insertTextNode(text, attributes: attributes)
    ..insertTextNode(text, attributes: attributes);

  await editor.startTesting();
  await editor.updateSelection(
    Selection.single(path: [1], startOffset: 0),
  );
  await editor.pressLogicKey(
    LogicalKeyboardKey.enter,
  );
  expect(editor.documentSelection, Selection.single(path: [2], startOffset: 0));

  await editor.updateSelection(
    Selection.single(path: [3], startOffset: text.length),
  );
  await editor.pressLogicKey(
    LogicalKeyboardKey.enter,
  );
  expect(editor.documentSelection, Selection.single(path: [4], startOffset: 0));

  if ([BuiltInAttributeKey.heading, BuiltInAttributeKey.quote]
      .contains(style)) {
    expect(editor.nodeAtPath([4])?.subtype, null);

    await editor.pressLogicKey(
      LogicalKeyboardKey.enter,
    );
    expect(
        editor.documentSelection, Selection.single(path: [5], startOffset: 0));
    expect(editor.nodeAtPath([5])?.subtype, null);
  } else {
    expect(editor.nodeAtPath([4])?.subtype, style);

    await editor.pressLogicKey(
      LogicalKeyboardKey.enter,
    );
    expect(
        editor.documentSelection, Selection.single(path: [4], startOffset: 0));
    expect(editor.nodeAtPath([4])?.subtype, null);
  }
}

Future<void> _testMultipleSelection(
    WidgetTester tester, bool isBackwardSelection) async {
  // Before
  //
  // Welcome to Appflowy 😁
  // Welcome to Appflowy 😁
  // Welcome to Appflowy 😁
  // Welcome to Appflowy 😁
  //
  // After
  //
  // Welcome
  // to Appflowy 😁
  //
  const text = 'Welcome to Appflowy 😁';
  final editor = tester.editor;
  var lines = 4;

  for (var i = 1; i <= lines; i++) {
    editor.insertTextNode(text);
  }

  await editor.startTesting();
  final start = Position(path: [0], offset: 7);
  final end = Position(path: [3], offset: 8);
  await editor.updateSelection(Selection(
    start: isBackwardSelection ? start : end,
    end: isBackwardSelection ? end : start,
  ));
  await editor.pressLogicKey(
    LogicalKeyboardKey.enter,
  );

  expect(editor.documentLength, 2);
  expect((editor.nodeAtPath([0]) as TextNode).toRawString(), 'Welcome');
  expect((editor.nodeAtPath([1]) as TextNode).toRawString(), 'to Appflowy 😁');
}
