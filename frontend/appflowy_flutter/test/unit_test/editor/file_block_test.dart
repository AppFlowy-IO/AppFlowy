import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileBlock:', () {
    test('insert file block in non-empty paragraph', () async {
      final document = Document.blank()
        ..insert(
          [0],
          [paragraphNode(text: 'Hello World')],
        );
      final editorState = EditorState(document: document);
      editorState.selection = Selection.collapsed(Position(path: [0]));

      // insert file block after the first line
      await editorState.insertEmptyFileBlock(GlobalKey());

      final afterDocument = editorState.document;
      expect(afterDocument.root.children.length, 2);
      expect(afterDocument.root.children[1].type, FileBlockKeys.type);
      expect(afterDocument.root.children[0].type, ParagraphBlockKeys.type);
      expect(
        afterDocument.root.children[0].delta!.toPlainText(),
        'Hello World',
      );
    });

    test('insert file block in empty paragraph', () async {
      final document = Document.blank()
        ..insert(
          [0],
          [paragraphNode(text: '')],
        );
      final editorState = EditorState(document: document);
      editorState.selection = Selection.collapsed(Position(path: [0]));

      await editorState.insertEmptyFileBlock(GlobalKey());

      final afterDocument = editorState.document;
      expect(afterDocument.root.children.length, 1);
      expect(afterDocument.root.children[0].type, FileBlockKeys.type);
    });
  });
}
