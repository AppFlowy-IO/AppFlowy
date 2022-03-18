import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';

import 'grid_service.dart';

class RowService {
  final GridRowData rowData;

  RowService(this.rowData);

  Future<Either<Row, FlowyError>> createRow() {
    CreateRowPayload payload = CreateRowPayload.create()
      ..gridId = rowData.gridId
      ..startRowId = rowData.rowId;

    return GridEventCreateRow(payload).send();
  }

  Future<Either<Row, FlowyError>> getRow() {
    QueryRowPayload payload = QueryRowPayload.create()
      ..gridId = rowData.gridId
      ..blockId = rowData.blockId
      ..rowId = rowData.rowId;

    return GridEventGetRow(payload).send();
  }
}

class GridCellData {
  final String gridId;
  final String rowId;
  final Field field;
  final Cell? cell;

  GridCellData({
    required this.rowId,
    required this.gridId,
    required this.field,
    required this.cell,
  });
}
