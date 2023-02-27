import 'dart:convert';

import 'package:flutter/foundation.dart';

typedef CellData = Map<String, Object>;
typedef ColumnData = List<CellData>;

class TableData extends ChangeNotifier {
  late List<ColumnData> cells = [];

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
  }

  TableData.fromJson(Map<String, dynamic> json) {
    print(json);
    final jData = json['table_data'] as List?;
    if (jData != null) {
      cells.addAll(jData.map(
          (col) => ColumnData.from(col.map((cell) => CellData.from(cell)))));
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

  CellData getCell(int col, int row) => cells[col][row];

  setCell(int col, int row, CellData val) => cells[col][row] = val;
}
