import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'row_service.freezed.dart';

class RowService {
  final String gridId;
  final String rowId;

  RowService({required this.gridId, required this.rowId});

  Future<Either<Row, FlowyError>> createRow() {
    CreateRowPayload payload = CreateRowPayload.create()
      ..gridId = gridId
      ..startRowId = rowId;

    return GridEventCreateRow(payload).send();
  }

  Future<Either<Row, FlowyError>> getRow() {
    final payload = RowIdentifierPayload.create()
      ..gridId = gridId
      ..rowId = rowId;

    return GridEventGetRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteRow() {
    final payload = RowIdentifierPayload.create()
      ..gridId = gridId
      ..rowId = rowId;

    return GridEventDeleteRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateRow() {
    final payload = RowIdentifierPayload.create()
      ..gridId = gridId
      ..rowId = rowId;

    return GridEventDuplicateRow(payload).send();
  }
}

@freezed
class CellData with _$CellData {
  const factory CellData({
    required String gridId,
    required String rowId,
    required Field field,
    Cell? cell,
  }) = _CellData;
}

@freezed
class RowData with _$RowData {
  const factory RowData({
    required String gridId,
    required String rowId,
    required List<Field> fields,
    required double height,
  }) = _RowData;

  factory RowData.fromBlockRow(GridBlockRow row, List<Field> fields) {
    return RowData(
      gridId: row.gridId,
      rowId: row.rowId,
      fields: fields,
      height: row.height,
    );
  }
}

@freezed
class GridBlockRow with _$GridBlockRow {
  const factory GridBlockRow({
    required String gridId,
    required String rowId,
    required double height,
  }) = _GridBlockRow;
}
