import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';

class RowService {
  final String gridId;
  final String blockId;
  final String rowId;

  RowService(
      {required this.gridId, required this.blockId, required this.rowId});

  Future<Either<RowPB, FlowyError>> createRow() {
    CreateRowPayloadPB payload = CreateRowPayloadPB.create()
      ..gridId = gridId
      ..startRowId = rowId;

    return GridEventCreateRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveRow(
      String rowId, int fromIndex, int toIndex) {
    final payload = MoveItemPayloadPB.create()
      ..gridId = gridId
      ..itemId = rowId
      ..ty = MoveItemTypePB.MoveRow
      ..fromIndex = fromIndex
      ..toIndex = toIndex;

    return GridEventMoveItem(payload).send();
  }

  Future<Either<OptionalRowPB, FlowyError>> getRow() {
    final payload = RowIdPB.create()
      ..gridId = gridId
      ..blockId = blockId
      ..rowId = rowId;

    return GridEventGetRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteRow() {
    final payload = RowIdPB.create()
      ..gridId = gridId
      ..blockId = blockId
      ..rowId = rowId;

    return GridEventDeleteRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateRow() {
    final payload = RowIdPB.create()
      ..gridId = gridId
      ..blockId = blockId
      ..rowId = rowId;

    return GridEventDuplicateRow(payload).send();
  }
}
