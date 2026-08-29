import 'package:appflowy/plugins/document/presentation/editor_plugins/code_block/code_block_arrow_command.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('arrow up in code block:', () {
    EditorState createEditor({
      required String code,
      required int offset,
      bool withSurroundingParagraphs = true,
    }) {
      final nodes = <Node>[
        if (withSurroundingParagraphs) paragraphNode(text: 'before'),
        codeBlockNode(delta: Delta()..insert(code)),
        if (withSurroundingParagraphs) paragraphNode(text: 'after'),
      ];
      final document = Document.blank()..insert([0], nodes);
      final editorState = EditorState(document: document);
      final codePath = withSurroundingParagraphs ? [1] : [0];
      editorState.selection = Selection.collapsed(
        Position(path: codePath, offset: offset),
      );
      return editorState;
    }

    test('moves to the previous line at the same column', () async {
      // "line1\nline2\nline3"
      // line2 starts at offset 6; cursor on the 'i' of line2 (offset 7).
      const code = 'line1\nline2\nline3';
      final editorState = createEditor(code: code, offset: 7);

      final result = await arrowUpInCodeBlock.execute(editorState);

      expect(result, KeyEventResult.handled);
      expect(editorState.selection, Selection.collapsed(Position(path: [1], offset: 1)));
      expect(
        editorState.getNodeAtPath([1])!.type,
        CodeBlockKeys.type,
      );

      editorState.dispose();
    });

    test('moves from the last line to the middle line', () async {
      const code = 'line1\nline2\nline3';
      // "line3" starts at offset 12; cursor at start of last line.
      final editorState = createEditor(code: code, offset: 12);

      final result = await arrowUpInCodeBlock.execute(editorState);

      expect(result, KeyEventResult.handled);
      expect(editorState.selection, Selection.collapsed(Position(path: [1], offset: 6)));

      editorState.dispose();
    });

    test('clamps the column when the previous line is shorter', () async {
      const code = 'hi\nhello';
      // "hello" starts at 3; cursor on the last 'l' (offset 6, column 3).
      final editorState = createEditor(code: code, offset: 6);

      final result = await arrowUpInCodeBlock.execute(editorState);

      expect(result, KeyEventResult.handled);
      // Previous line "hi" has length 2, so land at its end (offset 2).
      expect(editorState.selection, Selection.collapsed(Position(path: [1], offset: 2)));

      editorState.dispose();
    });

    test('is ignored on the first line so the default handler can leave the block', () async {
      const code = 'line1\nline2';
      final editorState = createEditor(code: code, offset: 3);

      final result = await arrowUpInCodeBlock.execute(editorState);

      expect(result, KeyEventResult.ignored);
      expect(editorState.selection, Selection.collapsed(Position(path: [1], offset: 3)));

      editorState.dispose();
    });

    test('is ignored when the caret is not in a code block', () async {
      final document = Document.blank()
        ..insert([
          0,
        ], [
          paragraphNode(text: 'hello\nworld'),
        ]);
      final editorState = EditorState(document: document);
      editorState.selection = Selection.collapsed(
        Position(path: [0], offset: 8),
      );

      final result = await arrowUpInCodeBlock.execute(editorState);

      expect(result, KeyEventResult.ignored);
      expect(editorState.selection, Selection.collapsed(Position(path: [0], offset: 8)));

      editorState.dispose();
    });

    test('is ignored when the selection is not collapsed', () async {
      const code = 'line1\nline2';
      final editorState = createEditor(code: code, offset: 7);
      editorState.selection = Selection(
        start: Position(path: [1], offset: 6),
        end: Position(path: [1], offset: 11),
      );

      final result = await arrowUpInCodeBlock.execute(editorState);

      expect(result, KeyEventResult.ignored);

      editorState.dispose();
    });

    test('moves from a later line onto an empty first line', () async {
      const code = '\nsecond';
      final editorState = createEditor(code: code, offset: 1);

      final result = await arrowUpInCodeBlock.execute(editorState);

      expect(result, KeyEventResult.handled);
      expect(
        editorState.selection,
        Selection.collapsed(Position(path: [1])),
      );

      editorState.dispose();
    });
  });
}
