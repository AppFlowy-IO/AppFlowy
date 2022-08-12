import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Enter key without shift handler', () {
    testWidgets('Pressing enter key in empty document', (tester) async {
      final editor = tester.editor
        ..initialize()
        ..insertEmptyTextNode();
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

    testWidgets('Pressing enter key in non-empty document', (tester) async {
      const text = 'Welcome to Appflowy 😁';
      var lines = 5;

      final editor = tester.editor..initialize();
      for (var i = 1; i <= lines; i++) {
        editor.insertTextNode(text: text);
      }
      await editor.startTesting();

      expect(editor.documentLength, lines);

      // Pressing the enter key in last line.
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
      expect(lastNode.delta.toRawString(), text);
      expect((lastNode.previous as TextNode).delta.toRawString(), '');
      expect(
          (lastNode.previous!.previous as TextNode).delta.toRawString(), text);
    });
  });
}
