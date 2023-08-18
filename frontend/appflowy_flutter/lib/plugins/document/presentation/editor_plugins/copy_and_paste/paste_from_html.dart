import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/editor_state_paste_node_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension PasteFromHtml on EditorState {
  Future<void> pasteHtml(String html) async {
    final nodes = htmlToDocument(html).root.children;
    if (nodes.isEmpty) {
      return;
    }
    if (nodes.length == 1) {
      await pasteSingleLineNode(nodes.first);
    } else {
      await pasteMultiLineNodes(nodes.toList());
    }
  }
}
