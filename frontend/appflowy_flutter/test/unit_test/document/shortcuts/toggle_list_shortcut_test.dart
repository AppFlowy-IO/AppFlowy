import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toggle list shortcut:', () {
    Document createDocument(List<Node> nodes) {
      final document = Document.blank();
      document.insert([0], nodes);
      return document;
    }

    setUpAll(() {
      Log.shared.disableLog = true;
    });

    tearDownAll(() {
      Log.shared.disableLog = false;
    });

    testWidgets('> + #', (tester) async {
      const heading1 = '>Heading 1';
      const paragraph1 = 'paragraph 1';
      const paragraph2 = 'paragraph 2';

      final document = createDocument([
        headingNode(level: 1, text: heading1),
        paragraphNode(text: paragraph1),
        paragraphNode(text: paragraph2),
      ]);

      final editorState = EditorState(document: document);
      editorState.selection = Selection.collapsed(
        Position(path: [0], offset: 1),
      );

      final result = await formatGreaterToToggleList.execute(editorState);
      expect(result, true);

      expect(editorState.document.root.children.length, 1);
      final node = editorState.document.root.children[0];
      expect(node.type, ToggleListBlockKeys.type);
      expect(node.attributes[ToggleListBlockKeys.level], 1);
      expect(node.delta!.toPlainText(), 'Heading 1');
      expect(node.children.length, 2);
      expect(node.children[0].delta!.toPlainText(), paragraph1);
      expect(node.children[1].delta!.toPlainText(), paragraph2);

      editorState.dispose();
    });
  });
}
