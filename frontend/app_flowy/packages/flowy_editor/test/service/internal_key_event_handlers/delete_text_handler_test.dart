import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('delete_text_handler.dart', () {
    testWidgets('Presses backspace key in empty document', (tester) async {
      // Before
      //
      // [Empty Line]
      //
      // After
      //
      // [Empty Line]
      //
      final editor = tester.editor..insertEmptyTextNode();
      await editor.startTesting();
      await editor.updateSelection(
        Selection.single(path: [0], startOffset: 0),
      );
      // Pressing the backspace key continuously.
      for (int i = 1; i <= 1; i++) {
        await editor.pressLogicKey(
          LogicalKeyboardKey.backspace,
        );
        expect(editor.documentLength, 1);
        expect(editor.documentSelection,
            Selection.single(path: [0], startOffset: 0));
      }
    });
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
  // [Style] Welcome to Appflowy 😁Welcome to Appflowy 😁
  //
  testWidgets('Presses backspace key in styled text', (tester) async {
    await _deleteStyledText(tester, StyleKey.checkbox);
  });
}

Future<void> _deleteStyledText(WidgetTester tester, String style) async {
  const text = 'Welcome to Appflowy 😁';
  Attributes attributes = {
    StyleKey.subtype: style,
  };
  if (style == StyleKey.checkbox) {
    attributes[StyleKey.checkbox] = true;
  } else if (style == StyleKey.numberList) {
    attributes[StyleKey.number] = 1;
  }
  final editor = tester.editor
    ..insertTextNode(text)
    ..insertTextNode(text, attributes: attributes)
    ..insertTextNode(text, attributes: attributes);

  await editor.startTesting();
  await editor.updateSelection(
    Selection.single(path: [2], startOffset: 0),
  );
  await editor.pressLogicKey(
    LogicalKeyboardKey.backspace,
  );
  expect(editor.documentSelection, Selection.single(path: [2], startOffset: 0));

  await editor.pressLogicKey(
    LogicalKeyboardKey.backspace,
  );
  expect(editor.documentLength, 2);
  expect(editor.documentSelection,
      Selection.single(path: [1], startOffset: text.length));
  expect(editor.nodeAtPath([1])?.subtype, style);
  expect((editor.nodeAtPath([1]) as TextNode).toRawString(), text * 2);

  await editor.updateSelection(
    Selection.single(path: [1], startOffset: 0),
  );
  await editor.pressLogicKey(
    LogicalKeyboardKey.backspace,
  );
  expect(editor.documentLength, 2);
  expect(editor.documentSelection, Selection.single(path: [1], startOffset: 0));
  expect(editor.nodeAtPath([1])?.subtype, null);
}
