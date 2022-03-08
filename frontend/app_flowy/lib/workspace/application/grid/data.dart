import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';

class GridInfo {
  List<Row> rows;
  List<Field> fields;

  GridInfo({
    required this.rows,
    required this.fields,
  });

  GridRowData rowAtIndex(int index) {
    final row = rows[index];
    return GridRowData(
      row: row,
      fields: fields,
      cellMap: row.cellByFieldId,
    );
  }

  int numberOfRows() {
    return rows.length;
  }
}

class GridRowData {
  Row row;
  List<Field> fields;
  Map<String, Cell> cellMap;
  GridRowData({
    required this.row,
    required this.fields,
    required this.cellMap,
  });
}
