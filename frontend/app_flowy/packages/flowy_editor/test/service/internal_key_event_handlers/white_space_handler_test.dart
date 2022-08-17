import 'package:flowy_editor/flowy_editor.dart';
import 'package:flowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/src/service/internal_key_event_handlers/whitespace_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('white_space_handler.dart', () {
    // Before
    //
    // Welcome to Appflowy 😁
    // Welcome to Appflowy 😁
    // Welcome to Appflowy 😁
    // Welcome to Appflowy 😁
    // Welcome to Appflowy 😁
    // Welcome to Appflowy 😁
    //
    // After
    // [h1]Welcome to Appflowy 😁
    // [h2]Welcome to Appflowy 😁
    // [h3]Welcome to Appflowy 😁
    // [h4]Welcome to Appflowy 😁
    // [h5]Welcome to Appflowy 😁
    // [h6]Welcome to Appflowy 😁
    //
    testWidgets('Presses whitespace key after #*', (tester) async {
      const maxSignCount = 6;
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor;
      for (var i = 1; i <= maxSignCount; i++) {
        editor.insertTextNode('${'#' * i}$text');
      }
      await editor.startTesting();

      for (var i = 1; i <= maxSignCount; i++) {
        await editor.updateSelection(
          Selection.single(path: [i - 1], startOffset: i),
        );
        await editor.pressLogicKey(LogicalKeyboardKey.space);

        final textNode = (editor.nodeAtPath([i - 1]) as TextNode);

        expect(textNode.subtype, StyleKey.heading);
        // StyleKey.h1 ~ StyleKey.h6
        expect(textNode.attributes.heading, 'h$i');
      }
    });

    // Before
    //
    // Welcome to Appflowy 😁
    // Welcome to Appflowy 😁
    // Welcome to Appflowy 😁
    // Welcome to Appflowy 😁
    // Welcome to Appflowy 😁
    // Welcome to Appflowy 😁
    //
    // After
    // [h1]##Welcome to Appflowy 😁
    // [h2]##Welcome to Appflowy 😁
    // [h3]##Welcome to Appflowy 😁
    // [h4]##Welcome to Appflowy 😁
    // [h5]##Welcome to Appflowy 😁
    // [h6]##Welcome to Appflowy 😁
    //
    testWidgets('Presses whitespace key inside #*', (tester) async {
      const maxSignCount = 6;
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor;
      for (var i = 1; i <= maxSignCount; i++) {
        editor.insertTextNode('${'###' * i}$text');
      }
      await editor.startTesting();

      for (var i = 1; i <= maxSignCount; i++) {
        await editor.updateSelection(
          Selection.single(path: [i - 1], startOffset: i),
        );
        await editor.pressLogicKey(LogicalKeyboardKey.space);

        final textNode = (editor.nodeAtPath([i - 1]) as TextNode);

        expect(textNode.subtype, StyleKey.heading);
        // StyleKey.h1 ~ StyleKey.h6
        expect(textNode.attributes.heading, 'h$i');
        expect(textNode.toRawString().startsWith('##'), true);
      }
    });

    // Before
    //
    // Welcome to Appflowy 😁
    //
    // After
    // [h1 ~ h6]##Welcome to Appflowy 😁
    //
    testWidgets('Presses whitespace key in heading styled text',
        (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor..insertTextNode(text);

      await editor.startTesting();

      const maxSignCount = 6;
      for (var i = 1; i <= maxSignCount; i++) {
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );

        final textNode = (editor.nodeAtPath([0]) as TextNode);

        await editor.insertText(textNode, '#' * i, 0);
        await editor.pressLogicKey(LogicalKeyboardKey.space);

        expect(textNode.subtype, StyleKey.heading);
        // StyleKey.h2 ~ StyleKey.h6
        expect(textNode.attributes.heading, 'h$i');
      }
    });

    testWidgets('Presses whitespace key after (un)checkbox symbols',
        (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor..insertTextNode(text);
      await editor.startTesting();

      final textNode = editor.nodeAtPath([0]) as TextNode;
      for (final symbol in unCheckboxListSymbols) {
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        await editor.insertText(textNode, symbol, 0);
        await editor.pressLogicKey(LogicalKeyboardKey.space);
        expect(textNode.subtype, StyleKey.checkbox);
        expect(textNode.attributes.check, false);
      }
    });

    testWidgets('Presses whitespace key after checkbox symbols',
        (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor..insertTextNode(text);
      await editor.startTesting();

      final textNode = editor.nodeAtPath([0]) as TextNode;
      for (final symbol in checkboxListSymbols) {
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        await editor.insertText(textNode, symbol, 0);
        await editor.pressLogicKey(LogicalKeyboardKey.space);
        expect(textNode.subtype, StyleKey.checkbox);
        expect(textNode.attributes.check, true);
      }
    });

    testWidgets('Presses whitespace key after bulleted list', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      final editor = tester.editor..insertTextNode(text);
      await editor.startTesting();

      final textNode = editor.nodeAtPath([0]) as TextNode;
      for (final symbol in bulletedListSymbols) {
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        await editor.insertText(textNode, symbol, 0);
        await editor.pressLogicKey(LogicalKeyboardKey.space);
        expect(textNode.subtype, StyleKey.bulletedList);
      }
    });
  });
}
