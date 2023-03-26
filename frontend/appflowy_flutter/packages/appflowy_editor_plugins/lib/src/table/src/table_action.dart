import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';

addCol(Node tableNode, Transaction transaction) {
  List<Node> cellNodes = [];
  final int rowsLen = tableNode.attributes['rowsLen'],
      colsLen = tableNode.attributes['colsLen'];

  var lastCellNode = getNode(tableNode, colsLen - 1, rowsLen - 1);
  for (var i = 0; i < rowsLen; i++) {
    final node = Node(
      type: kTableCellType,
      attributes: {
        'position': {'col': colsLen, 'row': i}
      },
    );
    node.insert(TextNode.empty());

    cellNodes.add(newCellNode(tableNode, node));
  }

  //TODO(zoli): this calls notifyListener rowsLen+1 times
  transaction.insertNodes(lastCellNode.path.next, cellNodes);
  transaction.updateNode(tableNode, {'colsLen': colsLen + 1});
}

addRow(Node tableNode, Transaction transaction) {
  final int rowsLen = tableNode.attributes['rowsLen'],
      colsLen = tableNode.attributes['colsLen'];
  for (var i = 0; i < colsLen; i++) {
    final node = Node(
      type: kTableCellType,
      attributes: {
        'position': {'col': i, 'row': rowsLen}
      },
    );
    node.insert(TextNode.empty());

    transaction.insertNode(getNode(tableNode, i, rowsLen - 1).path.next,
        newCellNode(tableNode, node));
  }
  transaction.updateNode(tableNode, {'rowsLen': rowsLen + 1});
}

newCellNode(Node tableNode, n) {
  final row = n.attributes['position']['row'] as int;
  final int rowsLen = tableNode.attributes['rowsLen'];

  if (!n.attributes.containsKey('height')) {
    double nodeHeight = double.tryParse(
        tableNode.attributes['config']['rowDefaultHeight'].toString())!;
    if (row < rowsLen) {
      nodeHeight = double.tryParse(
              getNode(tableNode, 0, row).attributes['height'].toString()) ??
          nodeHeight;
    }
    n.updateAttributes({'height': nodeHeight});
  }

  return n;
}

Node getNode(Node tableNode, int col, row) {
  return tableNode.children.firstWhereOrNull((n) =>
      n.attributes['position']['col'] == col &&
      n.attributes['position']['row'] == row)!;
}
