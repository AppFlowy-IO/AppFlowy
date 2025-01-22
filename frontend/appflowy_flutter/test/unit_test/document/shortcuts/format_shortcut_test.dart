import 'package:appflowy/plugins/document/presentation/editor_plugins/base/format_arrow_character.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('format shortcut:', () {
    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    test('turn = + > into ⇒', () async {
      final document = Document.blank()
        ..insert([
          0,
        ], [
          paragraphNode(text: '='),
        ]);

      final editorState = EditorState(document: document);
      editorState.selection = Selection.collapsed(
        Position(path: [0], offset: 1),
      );

      final result = await customFormatGreaterEqual.execute(editorState);
      expect(result, true);

      expect(editorState.document.root.children.length, 1);
      final node = editorState.document.root.children[0];
      expect(node.delta!.toPlainText(), '⇒');

      editorState.dispose();
    });

    test('turn - + > into →', () async {
      final document = Document.blank()
        ..insert([
          0,
        ], [
          paragraphNode(text: '-'),
        ]);

      final editorState = EditorState(document: document);
      editorState.selection = Selection.collapsed(
        Position(path: [0], offset: 1),
      );

      final result = await customFormatDashGreater.execute(editorState);
      expect(result, true);

      expect(editorState.document.root.children.length, 1);
      final node = editorState.document.root.children[0];
      expect(node.delta!.toPlainText(), '→');

      editorState.dispose();
    });
  });
}
