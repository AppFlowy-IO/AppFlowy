import 'dart:convert';

import 'package:flutter/foundation.dart';

class TableData extends ChangeNotifier {
  late List<List<String>> cells = [];

  TableData(this.cells);
  TableData.fromJson(String s) {
    List<dynamic> list = jsonDecode(s);
    cells = List<List<String>>.from(list.map((l) => List<String>.from(l)));
  }

  @override
  String toString() {
    return jsonEncode(cells).toString();
  }

  String getCell(int col, int row) => cells[col][row];

  //setCell(int col, int row, String val) => cells[col][row] = val;
  setCell(int col, int row, String val) {
    print(cells);
    cells[col][row] = val;
    print(cells);

    notifyListeners();
  }
}
