import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';

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

class CellData extends Equatable {
  final String gridId;
  final String rowId;
  final Field field;
  final Cell? cell;

  const CellData({
    required this.rowId,
    required this.gridId,
    required this.field,
    required this.cell,
  });

  @override
  List<Object?> get props => [cell, field];
}
