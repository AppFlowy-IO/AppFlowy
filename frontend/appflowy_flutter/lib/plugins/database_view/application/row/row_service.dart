import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:fixnum/fixnum.dart';

class RowBackendService {
  final String viewId;

  RowBackendService({
    required this.viewId,
  });

  Future<Either<RowPB, FlowyError>> createRow(Int64 rowId) {
    final payload = CreateRowPayloadPB.create()
      ..viewId = viewId
      ..startRowId = rowId;

    return DatabaseEventCreateRow(payload).send();
  }

  Future<Either<OptionalRowPB, FlowyError>> getRow(Int64 rowId) {
    final payload = RowIdPB.create()
      ..viewId = viewId
      ..rowId = rowId;

    return DatabaseEventGetRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteRow(Int64 rowId) {
    final payload = RowIdPB.create()
      ..viewId = viewId
      ..rowId = rowId;

    return DatabaseEventDeleteRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateRow(Int64 rowId) {
    final payload = RowIdPB.create()
      ..viewId = viewId
      ..rowId = rowId;

    return DatabaseEventDuplicateRow(payload).send();
  }
}
