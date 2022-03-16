import 'package:app_flowy/workspace/application/grid/data.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';

class RowService {
  final GridRowData rowData;

  RowService(this.rowData);

  Future<Either<Row, FlowyError>> createRow() {
    CreateRowPayload payload = CreateRowPayload.create()
      ..gridId = rowData.gridId
      ..upperRowId = rowData.row.id;

    return GridEventCreateRow(payload).send();
  }
}
