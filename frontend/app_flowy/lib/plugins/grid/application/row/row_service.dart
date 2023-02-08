import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/grid_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group_changeset.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/row_entities.pb.dart';

class RowFFIService {
  final String databaseId;

  RowFFIService({
    required this.databaseId,
  });

  Future<Either<RowPB, FlowyError>> createRow(String rowId) {
    final payload = CreateRowPayloadPB.create()
      ..databaseId = databaseId
      ..startRowId = rowId;

    return DatabaseEventCreateRow(payload).send();
  }

  Future<Either<OptionalRowPB, FlowyError>> getRow(String rowId) {
    final payload = RowIdPB.create()
      ..databaseId = databaseId
      ..rowId = rowId;

    return DatabaseEventGetRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteRow(String rowId) {
    final payload = RowIdPB.create()
      ..databaseId = databaseId
      ..rowId = rowId;

    return DatabaseEventDeleteRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateRow(String rowId) {
    final payload = RowIdPB.create()
      ..databaseId = databaseId
      ..rowId = rowId;

    return DatabaseEventDuplicateRow(payload).send();
  }
}

class MoveRowFFIService {
  final String viewId;

  MoveRowFFIService({
    required this.viewId,
  });

  Future<Either<Unit, FlowyError>> moveRow({
    required String fromRowId,
    required String toRowId,
  }) {
    var payload = MoveRowPayloadPB.create()
      ..viewId = viewId
      ..fromRowId = fromRowId
      ..toRowId = toRowId;

    return DatabaseEventMoveRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveGroupRow({
    required String fromRowId,
    required String toGroupId,
    required String? toRowId,
  }) {
    var payload = MoveGroupRowPayloadPB.create()
      ..viewId = viewId
      ..fromRowId = fromRowId
      ..toGroupId = toGroupId;

    if (toRowId != null) {
      payload.toRowId = toRowId;
    }

    return DatabaseEventMoveGroupRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveGroup({
    required String fromGroupId,
    required String toGroupId,
  }) {
    final payload = MoveGroupPayloadPB.create()
      ..viewId = viewId
      ..fromGroupId = fromGroupId
      ..toGroupId = toGroupId;

    return DatabaseEventMoveGroup(payload).send();
  }
}
