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
            endOffset: textNode.toPlainText().length,
          ),
        );
        expect(allCode, true);
        expect(textNode.toPlainText(), 'AppFlowy');
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
            endOffset: textNode.toPlainText().length,
          ),
        );
        expect(allCode, true);
        expect(textNode.toPlainText(), 'AppFlowy');
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
            endOffset: textNode.toPlainText().length,
          ),
        );
        expect(allCode, false);
        expect(textNode.toPlainText(), text);
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
            endOffset: textNode.toPlainText().length,
          ),
        );
        expect(allCode, true);
        expect(textNode.toPlainText(), '`AppFlowy');
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
            endOffset: textNode.toPlainText().length,
          ),
        );
        expect(allCode, false);
        expect(textNode.toPlainText(), text);
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
            endOffset: textNode.toPlainText().length,
          ),
        );
        expect(allStrikethrough, true);
        expect(textNode.toPlainText(), 'AppFlowy');
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
            endOffset: textNode.toPlainText().length,
          ),
        );
        expect(allStrikethrough, true);
        expect(textNode.toPlainText(), 'AppFlowy');
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
            endOffset: textNode.toPlainText().length,
          ),
        );
        expect(allStrikethrough, true);
        expect(textNode.toPlainText(), '~AppFlowy');
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
            endOffset: textNode.toPlainText().length,
          ),
        );
        expect(allStrikethrough, false);
        expect(textNode.toPlainText(), text);
      });
    });

    group('convert geater to blockquote', () {
      Future<void> insertGreater(
        EditorWidgetTester editor, {
        int repeat = 1,
      }) async {
        for (var i = 0; i < repeat; i++) {
          await editor.pressLogicKey(
            LogicalKeyboardKey.greater,
            isShiftPressed: true,
          );
        }
      }

      testWidgets('>AppFlowy to blockquote AppFlowy', (tester) async {
        const text = 'AppFlowy';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        await insertGreater(editor);
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }

        final isQuote = textNode.subtype == BuiltInAttributeKey.quote;
        expect(isQuote, true);
        expect(textNode.toPlainText(), 'AppFlowy');
      });

      testWidgets('AppFlowy> nothing changes', (tester) async {
        const text = 'AppFlowy';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await insertGreater(editor);

        final isQuote = textNode.subtype == BuiltInAttributeKey.quote;
        expect(isQuote, false);
        expect(textNode.toPlainText(), text);
      });

      testWidgets('> in front of text to blockquote', (tester) async {
        const text = 'AppFlowy';
        final editor = tester.editor..insertTextNode('');
        await editor.startTesting();
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        final textNode = editor.nodeAtPath([0]) as TextNode;
        for (var i = 0; i < text.length; i++) {
          await editor.insertText(textNode, text[i], i);
        }
        await editor.updateSelection(
          Selection.single(path: [0], startOffset: 0),
        );
        await insertGreater(editor);

        final isQuote = textNode.subtype == BuiltInAttributeKey.quote;
        expect(isQuote, true);
        expect(textNode.toPlainText(), text);
      });
    });
  });
}
