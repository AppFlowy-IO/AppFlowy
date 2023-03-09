import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/row_entities.pb.dart';

class RowBackendService {
  final String viewId;

  RowBackendService({
    required this.viewId,
  });

  Future<Either<RowPB, FlowyError>> createRow(String rowId) {
    final payload = CreateRowPayloadPB.create()
      ..viewId = viewId
      ..startRowId = rowId;

    return DatabaseEventCreateRow(payload).send();
  }

  Future<Either<OptionalRowPB, FlowyError>> getRow(String rowId) {
    final payload = RowIdPB.create()
      ..viewId = viewId
      ..rowId = rowId;

    return DatabaseEventGetRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteRow(String rowId) {
    final payload = RowIdPB.create()
      ..viewId = viewId
      ..rowId = rowId;

    return DatabaseEventDeleteRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateRow(String rowId) {
    final payload = RowIdPB.create()
      ..viewId = viewId
      ..rowId = rowId;

    return DatabaseEventDuplicateRow(payload).send();
  }
}
