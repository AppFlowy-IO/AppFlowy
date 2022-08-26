import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/image/image_node_widget.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('backspace_handler.dart', () {
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
  // Welcome to Appflowy 😁
  // Welcome to Appflowy 😁
  //
  // After
  //
  // Welcome to Appflowy 😁
  // Welcome t Appflowy 😁
  // Welcome Appflowy 😁
  //
  // Then
  // Welcome to Appflowy 😁
  //
  testWidgets(
      'Presses backspace key in non-empty document and selection is backward',
      (tester) async {
    await _deleteTextByBackspace(tester, true);
  });
  testWidgets(
      'Presses backspace key in non-empty document and selection is forward',
      (tester) async {
    await _deleteTextByBackspace(tester, false);
  });

  // Before
  //
  // Welcome to Appflowy 😁
  // Welcome to Appflowy 😁
  // Welcome to Appflowy 😁
  //
  // After
  //
  // Welcome to Appflowy 😁
  // Welcome t Appflowy 😁
  // Welcome Appflowy 😁
  //
  // Then
  // Welcome to Appflowy 😁
  //
  testWidgets(
      'Presses delete key in non-empty document and selection is backward',
      (tester) async {
    await _deleteTextByDelete(tester, true);
  });
  testWidgets(
      'Presses delete key in non-empty document and selection is forward',
      (tester) async {
    await _deleteTextByDelete(tester, false);
  });

  // Before
  //
  // Welcome to Appflowy 😁
  // Welcome to Appflowy 😁
  //
  // After
  //
  // Welcome to Appflowy 😁Welcome Appflowy 😁
  testWidgets(
      'Presses delete key in non-empty document and selection is at the end of the text',
      (tester) async {
    const text = 'Welcome to Appflowy 😁';
    final editor = tester.editor
      ..insertTextNode(text)
      ..insertTextNode(text);
    await editor.startTesting();

    // delete 'o'
    await editor.updateSelection(
      Selection.single(path: [0], startOffset: text.length),
    );
    await editor.pressLogicKey(LogicalKeyboardKey.delete);

    expect(editor.documentLength, 1);
    expect(editor.documentSelection,
        Selection.single(path: [0], startOffset: text.length));
    expect((editor.nodeAtPath([0]) as TextNode).toRawString(), text * 2);
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
  testWidgets('Presses backspace key in styled text (checkbox)',
      (tester) async {
    await _deleteStyledTextByBackspace(tester, StyleKey.checkbox);
  });
  testWidgets('Presses backspace key in styled text (bulletedList)',
      (tester) async {
    await _deleteStyledTextByBackspace(tester, StyleKey.bulletedList);
  });
  testWidgets('Presses backspace key in styled text (heading)', (tester) async {
    await _deleteStyledTextByBackspace(tester, StyleKey.heading);
  });
  testWidgets('Presses backspace key in styled text (quote)', (tester) async {
    await _deleteStyledTextByBackspace(tester, StyleKey.quote);
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
  // [Style] Welcome to Appflowy 😁
  //
  testWidgets('Presses delete key in styled text (checkbox)', (tester) async {
    await _deleteStyledTextByDelete(tester, StyleKey.checkbox);
  });
  testWidgets('Presses delete key in styled text (bulletedList)',
      (tester) async {
    await _deleteStyledTextByDelete(tester, StyleKey.bulletedList);
  });
  testWidgets('Presses delete key in styled text (heading)', (tester) async {
    await _deleteStyledTextByDelete(tester, StyleKey.heading);
  });
  testWidgets('Presses delete key in styled text (quote)', (tester) async {
    await _deleteStyledTextByDelete(tester, StyleKey.quote);
  });

  // Before
  //
  // Welcome to Appflowy 😁
  // Welcome to Appflowy 😁
  // [Image]
  // Welcome to Appflowy 😁
  // Welcome to Appflowy 😁
  //
  // After
  //
  // Welcome to Appflowy 😁
  // Welcome to Appflowy 😁
  //
  testWidgets('Deletes the image surrounded by text', (tester) async {
    mockNetworkImagesFor(() async {
      const text = 'Welcome to Appflowy 😁';
      const src = 'https://s1.ax1x.com/2022/08/26/v2sSbR.jpg';
      final editor = tester.editor
        ..insertTextNode(text)
        ..insertTextNode(text)
        ..insertImageNode(src)
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();

      expect(editor.documentLength, 5);
      expect(find.byType(ImageNodeWidget), findsOneWidget);

      await editor.updateSelection(
        Selection(
          start: Position(path: [1], offset: 0),
          end: Position(path: [3], offset: text.length),
        ),
      );

      await editor.pressLogicKey(LogicalKeyboardKey.backspace);
      expect(editor.documentLength, 3);
      expect(find.byType(ImageNodeWidget), findsNothing);
      expect(
        editor.documentSelection,
        Selection.single(path: [1], startOffset: 0),
      );
    });
  });

  testWidgets('Deletes the first image', (tester) async {
    mockNetworkImagesFor(() async {
      const text = 'Welcome to Appflowy 😁';
      const src = 'https://s1.ax1x.com/2022/08/26/v2sSbR.jpg';
      final editor = tester.editor
        ..insertImageNode(src)
        ..insertTextNode(text)
        ..insertTextNode(text);
      await editor.startTesting();

      expect(editor.documentLength, 3);
      expect(find.byType(ImageNodeWidget), findsOneWidget);

      await editor.updateSelection(
        Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: 1),
        ),
      );

      await editor.pressLogicKey(LogicalKeyboardKey.backspace);
      expect(editor.documentLength, 2);
      expect(find.byType(ImageNodeWidget), findsNothing);
    });
  });
}

Future<void> _deleteStyledTextByBackspace(
    WidgetTester tester, String style) async {
  const text = 'Welcome to Appflowy 😁';
  Attributes attributes = {
    StyleKey.subtype: style,
  };
  if (style == StyleKey.checkbox) {
    attributes[StyleKey.checkbox] = true;
  } else if (style == StyleKey.numberList) {
    attributes[StyleKey.number] = 1;
  } else if (style == StyleKey.heading) {
    attributes[StyleKey.heading] = StyleKey.h1;
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

Future<void> _deleteStyledTextByDelete(
    WidgetTester tester, String style) async {
  const text = 'Welcome to Appflowy 😁';
  Attributes attributes = {
    StyleKey.subtype: style,
  };
  if (style == StyleKey.checkbox) {
    attributes[StyleKey.checkbox] = true;
  } else if (style == StyleKey.numberList) {
    attributes[StyleKey.number] = 1;
  } else if (style == StyleKey.heading) {
    attributes[StyleKey.heading] = StyleKey.h1;
  }
  final editor = tester.editor
    ..insertTextNode(text)
    ..insertTextNode(text, attributes: attributes)
    ..insertTextNode(text, attributes: attributes);

  await editor.startTesting();
  await editor.updateSelection(
    Selection.single(path: [1], startOffset: 0),
  );
  for (var i = 1; i < text.length; i++) {
    await editor.pressLogicKey(
      LogicalKeyboardKey.delete,
    );
    expect(
        editor.documentSelection, Selection.single(path: [1], startOffset: 0));
    expect(editor.nodeAtPath([1])?.subtype, style);
    expect((editor.nodeAtPath([1]) as TextNode).toRawString(),
        text.safeSubString(i));
  }

  await editor.pressLogicKey(
    LogicalKeyboardKey.delete,
  );
  expect(editor.documentLength, 2);
  expect(editor.documentSelection, Selection.single(path: [1], startOffset: 0));
  expect(editor.nodeAtPath([1])?.subtype, style);
  expect((editor.nodeAtPath([1]) as TextNode).toRawString(), text);
}

Future<void> _deleteTextByBackspace(
    WidgetTester tester, bool isBackwardSelection) async {
  const text = 'Welcome to Appflowy 😁';
  final editor = tester.editor
    ..insertTextNode(text)
    ..insertTextNode(text)
    ..insertTextNode(text);
  await editor.startTesting();

  // delete 'o'
  await editor.updateSelection(
    Selection.single(path: [1], startOffset: 10),
  );
  await editor.pressLogicKey(LogicalKeyboardKey.backspace);

  expect(editor.documentLength, 3);
  expect(editor.documentSelection, Selection.single(path: [1], startOffset: 9));
  expect((editor.nodeAtPath([1]) as TextNode).toRawString(),
      'Welcome t Appflowy 😁');

  // delete 'to '
  await editor.updateSelection(
    Selection.single(path: [2], startOffset: 8, endOffset: 11),
  );
  await editor.pressLogicKey(LogicalKeyboardKey.backspace);
  expect(editor.documentLength, 3);
  expect(editor.documentSelection, Selection.single(path: [2], startOffset: 8));
  expect((editor.nodeAtPath([2]) as TextNode).toRawString(),
      'Welcome Appflowy 😁');

  // delete 'Appflowy 😁
  // Welcome t Appflowy 😁
  // Welcome '
  final start = Position(path: [0], offset: 11);
  final end = Position(path: [2], offset: 8);
  await editor.updateSelection(Selection(
      start: isBackwardSelection ? start : end,
      end: isBackwardSelection ? end : start));
  await editor.pressLogicKey(LogicalKeyboardKey.backspace);
  expect(editor.documentLength, 1);
  expect(
      editor.documentSelection, Selection.single(path: [0], startOffset: 11));
  expect((editor.nodeAtPath([0]) as TextNode).toRawString(),
      'Welcome to Appflowy 😁');
}

Future<void> _deleteTextByDelete(
    WidgetTester tester, bool isBackwardSelection) async {
  const text = 'Welcome to Appflowy 😁';
  final editor = tester.editor
    ..insertTextNode(text)
    ..insertTextNode(text)
    ..insertTextNode(text);
  await editor.startTesting();

  // delete 'o'
  await editor.updateSelection(
    Selection.single(path: [1], startOffset: 9),
  );
  await editor.pressLogicKey(LogicalKeyboardKey.delete);

  expect(editor.documentLength, 3);
  expect(editor.documentSelection, Selection.single(path: [1], startOffset: 9));
  expect((editor.nodeAtPath([1]) as TextNode).toRawString(),
      'Welcome t Appflowy 😁');

  // delete 'to '
  await editor.updateSelection(
    Selection.single(path: [2], startOffset: 8, endOffset: 11),
  );
  await editor.pressLogicKey(LogicalKeyboardKey.delete);
  expect(editor.documentLength, 3);
  expect(editor.documentSelection, Selection.single(path: [2], startOffset: 8));
  expect((editor.nodeAtPath([2]) as TextNode).toRawString(),
      'Welcome Appflowy 😁');

  // delete 'Appflowy 😁
  // Welcome t Appflowy 😁
  // Welcome '
  final start = Position(path: [0], offset: 11);
  final end = Position(path: [2], offset: 8);
  await editor.updateSelection(Selection(
      start: isBackwardSelection ? start : end,
      end: isBackwardSelection ? end : start));
  await editor.pressLogicKey(LogicalKeyboardKey.delete);
  expect(editor.documentLength, 1);
  expect(
      editor.documentSelection, Selection.single(path: [0], startOffset: 11));
  expect((editor.nodeAtPath([0]) as TextNode).toRawString(),
      'Welcome to Appflowy 😁');
}
