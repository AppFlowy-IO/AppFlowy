import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/extensions/text_node_extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('markdown_syntax_to_styled_text_handler.dart', () {
    group('convert double asterisks to bold', () {
      Future<void> insertAsterisk(
        EditorWidgetTester editor, {
        int repeat = 1,
      }) async {
        for (var i = 0; i < repeat; i++) {
          await editor.pressLogicKey(
            LogicalKeyboardKey.asterisk,
            isShiftPressed: true,
          );
        }
      }

      testWidgets('**AppFlowy** to bold AppFlowy', (tester) async {
        const text = '**AppFlowy*';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertAsterisk(editor);
        final allBold = textNode.allSatisfyBoldInSelection(
          Selection.single(
            path: [0],
            startOffset: 0,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allBold, true);
        expect(textNode.toRawString(), 'AppFlowy');
      });

      testWidgets('App**Flowy** to bold AppFlowy', (tester) async {
        const text = 'App**Flowy*';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertAsterisk(editor);
        final allBold = textNode.allSatisfyBoldInSelection(
          Selection.single(
            path: [0],
            startOffset: 3,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allBold, true);
        expect(textNode.toRawString(), 'AppFlowy');
      });

      testWidgets('***AppFlowy** to bold *AppFlowy', (tester) async {
        const text = '***AppFlowy*';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertAsterisk(editor);
        final allBold = textNode.allSatisfyBoldInSelection(
          Selection.single(
            path: [0],
            startOffset: 1,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allBold, true);
        expect(textNode.toRawString(), '*AppFlowy');
      });

      testWidgets('**** nothing changes', (tester) async {
        const text = '***';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertAsterisk(editor);
        final allBold = textNode.allSatisfyBoldInSelection(
          Selection.single(
            path: [0],
            startOffset: 0,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allBold, false);
        expect(textNode.toRawString(), text);
      });
    });

    group('convert double underscores to bold', () {
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

      testWidgets('__AppFlowy__ to bold AppFlowy', (tester) async {
        const text = '__AppFlowy_';
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
        final allBold = textNode.allSatisfyBoldInSelection(
          Selection.single(
            path: [0],
            startOffset: 0,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allBold, true);
        expect(textNode.toRawString(), 'AppFlowy');
      });

      testWidgets('App__Flowy__ to bold AppFlowy', (tester) async {
        const text = 'App__Flowy_';
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
        final allBold = textNode.allSatisfyBoldInSelection(
          Selection.single(
            path: [0],
            startOffset: 3,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allBold, true);
        expect(textNode.toRawString(), 'AppFlowy');
      });

      testWidgets('___AppFlowy__ to bold _AppFlowy', (tester) async {
        const text = '___AppFlowy_';
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
        final allBold = textNode.allSatisfyBoldInSelection(
          Selection.single(
            path: [0],
            startOffset: 1,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allBold, true);
        expect(textNode.toRawString(), '_AppFlowy');
      });

      testWidgets('____ nothing changes', (tester) async {
        const text = '___';
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
        final allBold = textNode.allSatisfyBoldInSelection(
          Selection.single(
            path: [0],
            startOffset: 0,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allBold, false);
        expect(textNode.toRawString(), text);
      });
    });
  });
}
