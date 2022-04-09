import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'row_service.freezed.dart';

class RowService {
  final String gridId;
  final String rowId;
  final String blockId;

  RowService({required this.gridId, required this.rowId, required this.blockId});

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
