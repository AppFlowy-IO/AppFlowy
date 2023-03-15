import 'package:appflowy_editor_plugins/src/table/src/table_config.dart';
import 'package:flutter/foundation.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'dart:math';

import 'package:flutter/material.dart';

typedef CellData = Map<String, Object>;
typedef ColumnData = List<CellData>;
typedef ColumnNode = List<TextNode>;

class TableData extends ChangeNotifier {
  final List<ColumnData> _cells = [];
  final List<ColumnNode> _cellNodes = [];

  final TableConfig _config;

  final List<double> _rowsHeight = [], _colsWidth = [];

  // TODO(zoli): assertions: e.g that each column and row have equal cells
  TableData(List<List<String>> list, {config = const TableConfig()})
      : _config = config {
    assert(list.isNotEmpty);
    for (var i = 0; i < list.length; i++) {
      assert(list[i].isNotEmpty);

      _cells.add(ColumnData.from(list[i].map((cell) => CellData.from({
            "type": "text",
            "delta": [
              {"insert": cell}
            ]
          }))));
      assert(_cells[0].length == _cells[i].length);

      _colsWidth.add(_config.colDefaultWidth);
    }

    _fillRowsHeight();
  }

  TableData.fromJson(Map<String, dynamic> json)
      : _config = TableConfig.fromJson(json['config'] ?? {}) {
    assert(json['columns'] is List);
    assert(json['columns'].isNotEmpty);
    final jColumns = json['columns'] as List<dynamic>;

    for (var i = 0; i < jColumns.length; i++) {
      assert(jColumns[i].containsKey('cells'));

      assert(jColumns[i]['cells'] is List);
      assert(jColumns[i]['cells'].isNotEmpty);
      final jCells = jColumns[i]['cells'] as List<dynamic>;
      _cells.add(ColumnData.from(jCells.map((cell) => CellData.from(cell))));
      assert(_cells[0].length == _cells[i].length);

      var cw = _config.colDefaultWidth;
      if (jColumns[i].containsKey('width')) {
        cw = double.tryParse(jColumns[i]['width'].toString())!;
      }
      _colsWidth.add(cw);
    }

    _fillRowsHeight();
  }

  _fillRowsHeight() {
    for (var i = 0; i < rowsLen; i++) {
      _rowsHeight.add(_config.rowDefaultHeight);
    }
  }

  Map<String, Object> toJson() {
    var map = <String, Object>{'config': _config.toJson()};

    var columns = [];
    for (var i = 0; i < _cells.length; i++) {
      var cells = _cells[i]
          .map((cell) => Map<String, Object>.from(cell))
          .toList(growable: false);

      columns.add({'width': getColWidth(i), 'cells': cells});
    }
    map['columns'] = columns;

    return map;
  }

  CellData getCell(int col, row) => _cells[col][row];

  setCell(int col, row, CellData val) => _cells[col][row] = val;

  TextNode getCellNode(int col, row) => _cellNodes[col][row];

  setNode(int col, row, TextNode val) {
    if (_cellNodes.length <= col) {
      _cellNodes.add([val]);
    } else {
      _cellNodes[col].add(val);
    }
  }

  TableConfig get config => _config.clone();

  int get colsLen => _cells.length;

  int get rowsLen => _cells[0].length;

  double getRowHeight(int row) => _rowsHeight[row];

  double get colsHeight =>
      _rowsHeight.fold<double>(
          0, (prev, cur) => prev + cur + _config.tableBorderWidth) +
      _config.tableBorderWidth;

  double getColWidth(int col) => _colsWidth[col];

  double get colsWidth =>
      _colsWidth.fold<double>(
          0, (prev, cur) => prev + cur + _config.tableBorderWidth) +
      _config.tableBorderWidth;

  setColWidth(int col, double w) {
    w = w < _config.colMinimumWidth ? _config.colMinimumWidth : w;
    _colsWidth[col] = w;
    notifyListeners();
  }

  notifyNodeUpdate(int col, row) {
    var node = _cellNodes[col][row], height = node.rect.height;
    if (_rowsHeight.length <= row) {
      _rowsHeight.add(height);
      notifyListeners();
    } else {
      double maxHeight =
          _cellNodes.map<double>((c) => c[row].rect.height).reduce(max);

      if (_rowsHeight[row] != maxHeight) {
        _rowsHeight[row] = maxHeight;
        notifyListeners();
      }
    }
  }

  addCol() {
    _cells.add(ColumnData.generate(
      rowsLen,
      (_) => CellData.from({
        "type": "text",
        "delta": [
          {"insert": ''}
        ]
      }),
    ));

    _colsWidth.add(_config.colDefaultWidth);

    notifyListeners();
  }

  addRow() {
    for (var i = 0; i < _cells.length; i++) {
      _cells[i].add(
        CellData.from({
          "type": "text",
          "delta": [
            {"insert": ''}
          ]
        }),
      );
    }

    _rowsHeight.add(_config.rowDefaultHeight);

    notifyListeners();
  }
}
