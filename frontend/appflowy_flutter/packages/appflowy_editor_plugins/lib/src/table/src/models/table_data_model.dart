import 'package:flutter/foundation.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'dart:math';

import 'package:flutter/material.dart';

typedef CellData = Map<String, Object>;
typedef ColumnData = List<CellData>;
typedef ColumnNode = List<TextNode>;

class TableData extends ChangeNotifier {
  List<ColumnData> cells = [];
  List<ColumnNode> cellNodes = [];

  List<double> rowsHeight = [];

  // TODO(zoli): assertions: e.g that each column and row have equal cells
  TableData(List<List<String>> data) {
    cells.addAll(data.map((col) => col
        .map((cell) => CellData.from({
              "type": "text",
              "delta": [
                {"insert": cell}
              ]
            }))
        .toList()));

    fill();
  }

  TableData.fromJson(Map<String, dynamic> json) {
    final jData = json['table_data'] as List?;
    if (jData != null) {
      cells.addAll(jData.map(
          (col) => ColumnData.from(col.map((cell) => CellData.from(cell)))));
    }

    fill();
  }

  fill() {
    for (var i = 0; i < rowsLen; i++) {
      rowsHeight.add(40);
    }
  }

  Map<String, Object> toJson() {
    var map = <String, Object>{};
    map['table_data'] = cells
        .map((col) => col
            .map((cell) => Map<String, Object>.from(cell))
            .toList(growable: false))
        .toList(growable: false);

    return map;
  }

  CellData getCell(int col, row) => cells[col][row];

  setCell(int col, row, CellData val) => cells[col][row] = val;
  setNode(int col, row, TextNode val) {
    if (cellNodes.length <= col) {
      cellNodes.add([val]);
    } else {
      cellNodes[col].add(val);
    }
  }

  get colsLen => cells.length;
  get rowsLen => cells[0].length;

  double getRowHeight(int row) => rowsHeight[row];
  get colsHeight => rowsHeight.fold<double>(0, (prev, cur) => prev + cur);

  notifyNodeUpdate(int col, row) {
    var node = cellNodes[col][row], height = node.rect.height;
    if (rowsHeight.length <= col) {
      rowsHeight.add(height);
      notifyListeners();
    } else {
      double maxHeight =
          cellNodes.map<double>((col) => col[row].rect.height).reduce(max);

      if (rowsHeight[row] != maxHeight) {
        rowsHeight[row] = maxHeight;
        notifyListeners();
      }
    }
  }
}
