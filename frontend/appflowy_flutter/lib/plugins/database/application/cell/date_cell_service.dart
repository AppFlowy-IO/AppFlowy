import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/cell_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:fixnum/fixnum.dart';

final class DateCellBackendService {
  DateCellBackendService({
    required String viewId,
    required String fieldId,
    required String rowId,
  }) : cellId = CellIdPB.create()
          ..viewId = viewId
          ..fieldId = fieldId
          ..rowId = rowId;

  final CellIdPB cellId;

  Future<Either<Unit, FlowyError>> update({
    required bool includeTime,
    required bool isRange,
    DateTime? date,
    String? time,
    DateTime? endDate,
    String? endTime,
    String? reminderId,
  }) {
    final payload = DateChangesetPB.create()
      ..cellId = cellId
      ..includeTime = includeTime
      ..isRange = isRange;

    if (date != null) {
      final dateTimestamp = date.millisecondsSinceEpoch ~/ 1000;
      payload.date = Int64(dateTimestamp);
    }
    if (time != null) {
      payload.time = time;
    }
    if (endDate != null) {
      final dateTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;
      payload.endDate = Int64(dateTimestamp);
    }
    if (endTime != null) {
      payload.endTime = endTime;
    }
    if (reminderId != null) {
      payload.reminderId = reminderId;
    }

    return DatabaseEventUpdateDateCell(payload).send();
  }

  Future<Either<Unit, FlowyError>> clear() {
    final payload = DateChangesetPB.create()
      ..cellId = cellId
      ..clearFlag = true;

    return DatabaseEventUpdateDateCell(payload).send();
  }
}
