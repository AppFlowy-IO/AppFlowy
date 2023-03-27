import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:appflowy_editor_plugins/src/table/src/util.dart';

addCol(Node tableNode, Transaction transaction) {
  List<Node> cellNodes = [];
  final int rowsLen = tableNode.attributes['rowsLen'],
      colsLen = tableNode.attributes['colsLen'];

  var lastCellNode = getCellNode(tableNode, colsLen - 1, rowsLen - 1)!;
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

  // TODO(zoli): this calls notifyListener rowsLen+1 times. isn't there a better
  // way?
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

    transaction.insertNode(getCellNode(tableNode, i, rowsLen - 1)!.path.next,
        newCellNode(tableNode, node));
  }
  transaction.updateNode(tableNode, {'rowsLen': rowsLen + 1});
}

removeCol(Node tableNode, int col, Transaction transaction) {
  final int rowsLen = tableNode.attributes['rowsLen'],
      colsLen = tableNode.attributes['colsLen'];
  List<Node> nodes = [];
  for (var i = 0; i < rowsLen; i++) {
    nodes.add(getCellNode(tableNode, col, i)!);
  }
  transaction.deleteNodes(nodes);
  transaction.updateNode(tableNode, {'colsLen': colsLen - 1});
}

removeRow(Node tableNode, int row, Transaction transaction) {
  final int rowsLen = tableNode.attributes['rowsLen'],
      colsLen = tableNode.attributes['colsLen'];
  List<Node> nodes = [];
  for (var i = 0; i < colsLen; i++) {
    nodes.add(getCellNode(tableNode, i, row)!);
  }
  transaction.deleteNodes(nodes);
  transaction.updateNode(tableNode, {'rowsLen': rowsLen - 1});
}

newCellNode(Node tableNode, n) {
  final row = n.attributes['position']['row'] as int;
  final int rowsLen = tableNode.attributes['rowsLen'];

  if (!n.attributes.containsKey('height')) {
    double nodeHeight = double.tryParse(
        tableNode.attributes['config']['rowDefaultHeight'].toString())!;
    if (row < rowsLen) {
      nodeHeight = double.tryParse(getCellNode(tableNode, 0, row)!
              .attributes['height']
              .toString()) ??
          nodeHeight;
    }
    n.updateAttributes({'height': nodeHeight});
  }

  if (!n.attributes.containsKey('width')) {
    double nodeWidth = double.tryParse(
        tableNode.attributes['config']['colDefaultWidth'].toString())!;
    if (row < rowsLen) {
      nodeWidth = double.tryParse(
              getCellNode(tableNode, 0, row)!.attributes['width'].toString()) ??
          nodeWidth;
    }
    n.updateAttributes({'width': nodeWidth});
  }

  return n;
}
