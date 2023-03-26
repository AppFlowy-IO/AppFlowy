import 'dart:math';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_action.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_config.dart';
import 'package:appflowy_editor_plugins/src/table/table_const.dart';

typedef ColumnNode = List<Node>;

class TableNode {
  final TableConfig _config;

  final Node node;
  final List<ColumnNode> _cells = [];

  TableNode({
    required this.node,
  }) : _config = TableConfig.fromJson(node.attributes['config']) {
    assert(node.type == kTableType);
    assert(node.attributes.containsKey('colsLen'));
    assert(node.attributes['colsLen'] is int);
    assert(node.attributes.containsKey('rowsLen'));
    assert(node.attributes['rowsLen'] is int);

    assert(node.attributes['config']['rowDefaultHeight'] != null);
    assert(node.attributes['config']['colMinimumWidth'] != null);
    assert(node.attributes['config']['colDefaultWidth'] != null);

    final int colsCount = node.attributes['colsLen'];
    final int rowsCount = node.attributes['rowsLen'];
    assert(node.children.length == colsCount * rowsCount);
    assert(node.children.every((n) => n.attributes.containsKey('position')));
    assert(node.children.every((n) =>
        n.attributes['position'].containsKey('row') &&
        n.attributes['position'].containsKey('col')));

    for (var i = 0; i < colsCount; i++) {
      _cells.add([]);
      for (var j = 0; j < rowsCount; j++) {
        final cell = node.children.where((n) =>
            n.attributes['position']['col'] == i &&
            n.attributes['position']['row'] == j);
        assert(cell.length == 1);
        _cells[i].add(newCellNode(node, cell.first));
      }
    }
  }

  factory TableNode.fromJson(Map<String, Object> json) {
    return TableNode(node: Node.fromJson(json));
  }

  factory TableNode.fromList(List<List<String>> cols, {TableConfig? config}) {
    assert(cols.isNotEmpty);
    assert(cols[0].isNotEmpty);
    assert(cols.every((col) => col.length == cols[0].length));

    config = config ?? const TableConfig();

    Node node = Node(type: kTableType, attributes: {
      'colsLen': cols.length,
      'rowsLen': cols[0].length,
      'config': config.toJson()
    });
    for (var i = 0; i < cols.length; i++) {
      for (var j = 0; j < cols[0].length; j++) {
        final n = Node(
          type: kTableCellType,
          attributes: {
            'position': {'col': i, 'row': j}
          },
        );
        n.insert(TextNode(
          delta: Delta()..insert(cols[i][j]),
        ));

        node.insert(n);
      }
    }

    return TableNode(node: node);
  }

  Node getCell(int col, row) => _cells[col][row];

  TableConfig get config => _config.clone();

  int get colsLen => _cells.length;

  int get rowsLen => _cells.isNotEmpty ? _cells[0].length : 0;

  double getRowHeight(int row) =>
      double.tryParse(_cells[0][row].attributes['height'].toString()) ??
      _config.rowDefaultHeight;

  double get colsHeight =>
      List.generate(rowsLen, (idx) => idx).fold<double>(0,
          (prev, cur) => prev + getRowHeight(cur) + _config.tableBorderWidth) +
      _config.tableBorderWidth;

  double getColWidth(int col) =>
      double.tryParse(_cells[col][0].attributes['width'].toString()) ??
      _config.colDefaultWidth;

  double get tableWidth =>
      List.generate(colsLen, (idx) => idx).fold<double>(0,
          (prev, cur) => prev + getColWidth(cur) + _config.tableBorderWidth) +
      _config.tableBorderWidth;

  setColWidth(int col, double w) {
    w = w < _config.colMinimumWidth ? _config.colMinimumWidth : w;
    if (_cells[col][0].attributes['width'] != w) {
      _cells[col][0].updateAttributes({'width': w});
      for (var i = 0; i < rowsLen; i++) {
        updateRowHeight(i);
      }
      node.updateAttributes({'col${col}Width': w});
    }
  }

  updateRowHeight(int row) {
    double maxHeight = _cells
        .map<double>((c) => c[row].children.first.rect.height)
        .reduce(max);

    if (_cells[0][row].attributes['height'] != maxHeight) {
      for (var i = 0; i < colsLen; i++) {
        _cells[i][row].updateAttributes({'height': maxHeight});
      }
      node.updateAttributes({'colsHeight': colsHeight});
    }
  }
}
