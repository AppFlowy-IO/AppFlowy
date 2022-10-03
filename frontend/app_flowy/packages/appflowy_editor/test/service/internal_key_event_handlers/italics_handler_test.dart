import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/extensions/text_node_extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('italics_handler.dart', () {
    group('convert underscore to italic', () {
      Future<void> insertUnderscore(
        EditorWidgetTester editor, {
        int repeat = 1,
      }) async {
        for (var i = 0; i < repeat; i++) {
          await editor.pressLogicKey(
            LogicalKeyboardKey.underscore,
            isShiftPressed: true,
          );
        }
      }

      testWidgets('_AppFlowy_ to italic AppFlowy', (tester) async {
        const text = '_AppFlowy_';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertUnderscore(editor);
        final allItalic = textNode.allSatisfyItalicInSelection(
          Selection.single(
            path: [0],
            startOffset: 0,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allItalic, true);
        expect(textNode.toRawString(), 'AppFlowy');
      });
    });
  });
}