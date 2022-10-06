import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/extensions/text_node_extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('markdown_syntax_to_styled_text.dart', () {
    group('convert single backquote to code', () {
      Future<void> insertBackquote(
        EditorWidgetTester editor, {
        int repeat = 1,
      }) async {
        for (var i = 0; i < repeat; i++) {
          await editor.pressLogicKey(
            LogicalKeyboardKey.backquote,
          );
        }
      }

      testWidgets('`AppFlowy` to code AppFlowy', (tester) async {
        const text = '`AppFlowy';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertBackquote(editor);
        final allCode = textNode.allSatisfyCodeInSelection(
          Selection.single(
            path: [0],
            startOffset: 0,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allCode, true);
        expect(textNode.toRawString(), 'AppFlowy');
      });

      testWidgets('App`Flowy` to code AppFlowy', (tester) async {
        const text = 'App`Flowy';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertBackquote(editor);
        final allCode = textNode.allSatisfyCodeInSelection(
          Selection.single(
            path: [0],
            startOffset: 3,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allCode, true);
        expect(textNode.toRawString(), 'AppFlowy');
      });

      testWidgets('`` nothing changes', (tester) async {
        const text = '`';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertBackquote(editor);
        final allCode = textNode.allSatisfyCodeInSelection(
          Selection.single(
            path: [0],
            startOffset: 0,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allCode, false);
        expect(textNode.toRawString(), text);
      });
    });

    group('convert double backquote to code', () {
      Future<void> insertBackquote(
        EditorWidgetTester editor, {
        int repeat = 1,
      }) async {
        for (var i = 0; i < repeat; i++) {
          await editor.pressLogicKey(
            LogicalKeyboardKey.backquote,
          );
        }
      }

      testWidgets('```AppFlowy`` to code `AppFlowy', (tester) async {
        const text = '```AppFlowy`';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertBackquote(editor);
        final allCode = textNode.allSatisfyCodeInSelection(
          Selection.single(
            path: [0],
            startOffset: 1,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allCode, true);
        expect(textNode.toRawString(), '`AppFlowy');
      });

      testWidgets('```` nothing changes', (tester) async {
        const text = '```';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertBackquote(editor);
        final allCode = textNode.allSatisfyCodeInSelection(
          Selection.single(
            path: [0],
            startOffset: 0,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allCode, false);
        expect(textNode.toRawString(), text);
      });
    });

    group('convert double tilde to strikethrough', () {
      Future<void> insertTilde(
        EditorWidgetTester editor, {
        int repeat = 1,
      }) async {
        for (var i = 0; i < repeat; i++) {
          await editor.pressLogicKey(
            LogicalKeyboardKey.tilde,
            isShiftPressed: true,
          );
        }
      }

      testWidgets('~~AppFlowy~~ to strikethrough AppFlowy', (tester) async {
        const text = '~~AppFlowy~';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertTilde(editor);
        final allStrikethrough = textNode.allSatisfyStrikethroughInSelection(
          Selection.single(
            path: [0],
            startOffset: 0,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allStrikethrough, true);
        expect(textNode.toRawString(), 'AppFlowy');
      });

      testWidgets('App~~Flowy~~ to strikethrough AppFlowy', (tester) async {
        const text = 'App~~Flowy~';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertTilde(editor);
        final allStrikethrough = textNode.allSatisfyStrikethroughInSelection(
          Selection.single(
            path: [0],
            startOffset: 3,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allStrikethrough, true);
        expect(textNode.toRawString(), 'AppFlowy');
      });

      testWidgets('~~~AppFlowy~~ to bold ~AppFlowy', (tester) async {
        const text = '~~~AppFlowy~';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertTilde(editor);
        final allStrikethrough = textNode.allSatisfyStrikethroughInSelection(
          Selection.single(
            path: [0],
            startOffset: 1,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allStrikethrough, true);
        expect(textNode.toRawString(), '~AppFlowy');
      });

      testWidgets('~~~~ nothing changes', (tester) async {
        const text = '~~~';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertTilde(editor);
        final allStrikethrough = textNode.allSatisfyStrikethroughInSelection(
          Selection.single(
            path: [0],
            startOffset: 0,
            endOffset: textNode.toRawString().length,
          ),
        );
        expect(allStrikethrough, false);
        expect(textNode.toRawString(), text);
      });
    });
  });
}
