import 'package:appflowy_editor/appflowy_editor.dart';

extension PasteFromHtml on EditorState {
  Future<bool> pasteHtml(String html) async {
    final nodes = htmlToDocument(html).root.children.toList();
    // remove the front and back empty line
    while (nodes.isNotEmpty && nodes.first.delta?.isEmpty == true) {
      nodes.removeAt(0);
    }
    while (nodes.isNotEmpty && nodes.last.delta?.isEmpty == true) {
      nodes.removeLast();
    }
    // if there's no nodes being converted successfully, return false
    if (nodes.isEmpty) {
      return false;
    }
    if (nodes.length == 1) {
      await pasteSingleLineNode(nodes.first);
    } else {
      await pasteMultiLineNodes(nodes.toList());
    }
    return true;
  }
}
