import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:equatable/equatable.dart';

class GridInfo {
  final String gridId;
  List<Row> rows;
  List<Field> fields;

  GridInfo({
    required this.gridId,
    required this.rows,
    required this.fields,
  });

  GridRowData rowAtIndex(int index) {
    final row = rows[index];
    return GridRowData(
      gridId: gridId,
      row: row,
      fields: fields,
      cellMap: row.cellByFieldId,
    );
  }

  int numberOfRows() {
    return rows.length;
  }
}

class GridRowData extends Equatable {
  final String gridId;
  final Row row;
  final List<Field> fields;
  final Map<String, Cell> cellMap;
  const GridRowData({
    required this.gridId,
    required this.row,
    required this.fields,
    required this.cellMap,
  });

  @override
  List<Object> get props => [row.hashCode, cellMap];
}

class GridColumnData {
  final List<Field> fields;

  GridColumnData({required this.fields});
}
