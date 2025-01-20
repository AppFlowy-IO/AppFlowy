import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension PasteFromHtml on EditorState {
  Future<bool> pasteHtml(String html) async {
    final nodes = _convertHtmlToNodes(html);
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

  List<Node> _convertHtmlToNodes(String html) {
    final nodes = htmlToDocument(html).root.children.toList();

    // 1. remove the front and back empty line
    while (nodes.isNotEmpty && nodes.first.delta?.isEmpty == true) {
      nodes.removeAt(0);
    }
    while (nodes.isNotEmpty && nodes.last.delta?.isEmpty == true) {
      nodes.removeLast();
    }

    // 2. replace the legacy table nodes with the new simple table nodes
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node.type == TableBlockKeys.type) {
        nodes[i] = _convertTableToSimpleTable(node);
      }
    }

    return nodes;
  }

  // convert the legacy table node to the new simple table node
  // from type 'table' to type 'simple_table'
  Node _convertTableToSimpleTable(Node node) {
    if (node.type != TableBlockKeys.type) {
      return node;
    }

    // the table node should contains colsLen and rowsLen
    final colsLen = node.attributes[TableBlockKeys.colsLen];
    final rowsLen = node.attributes[TableBlockKeys.rowsLen];
    if (colsLen == null || rowsLen == null) {
      return node;
    }

    final rows = <List<Node>>[];
    final children = node.children;
    for (var i = 0; i < rowsLen; i++) {
      final row = <Node>[];
      for (var j = 0; j < colsLen; j++) {
        final cell = children
            .where(
              (n) =>
                  n.attributes[TableCellBlockKeys.rowPosition] == i &&
                  n.attributes[TableCellBlockKeys.colPosition] == j,
            )
            .firstOrNull;
        row.add(
          simpleTableCellBlockNode(
            children: cell?.children.map((e) => e.deepCopy()).toList() ??
                [paragraphNode()],
          ),
        );
      }
      rows.add(row);
    }

    return simpleTableBlockNode(
      children: rows.map((e) => simpleTableRowBlockNode(children: e)).toList(),
    );
  }
}
