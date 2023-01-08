import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/group_changeset.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/row_entities.pb.dart';

class RowFFIService {
  final String gridId;

  RowFFIService({
    required this.gridId,
  });

  Future<Either<RowPB, FlowyError>> createRow(String rowId) {
    final payload = CreateTableRowPayloadPB.create()
      ..gridId = gridId
      ..startRowId = rowId;

    return GridEventCreateTableRow(payload).send();
  }

  Future<Either<OptionalRowPB, FlowyError>> getRow(String rowId) {
    final payload = RowIdPB.create()
      ..gridId = gridId
      ..rowId = rowId;

    return GridEventGetRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteRow(String rowId) {
    final payload = RowIdPB.create()
      ..gridId = gridId
      ..rowId = rowId;

    return GridEventDeleteRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateRow(String rowId) {
    final payload = RowIdPB.create()
      ..gridId = gridId
      ..rowId = rowId;

    return GridEventDuplicateRow(payload).send();
  }
}

class MoveRowFFIService {
  final String gridId;

  MoveRowFFIService({
    required this.gridId,
  });

  Future<Either<Unit, FlowyError>> moveRow({
    required String fromRowId,
    required String toRowId,
  }) {
    var payload = MoveRowPayloadPB.create()
      ..viewId = gridId
      ..fromRowId = fromRowId
      ..toRowId = toRowId;

    return GridEventMoveRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveGroupRow({
    required String fromRowId,
    required String toGroupId,
    required String? toRowId,
  }) {
    var payload = MoveGroupRowPayloadPB.create()
      ..viewId = gridId
      ..fromRowId = fromRowId
      ..toGroupId = toGroupId;

    if (toRowId != null) {
      payload.toRowId = toRowId;
    }

    return GridEventMoveGroupRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveGroup({
    required String fromGroupId,
    required String toGroupId,
  }) {
    final payload = MoveGroupPayloadPB.create()
      ..viewId = gridId
      ..fromGroupId = fromGroupId
      ..toGroupId = toGroupId;

    return GridEventMoveGroup(payload).send();
  }
}
