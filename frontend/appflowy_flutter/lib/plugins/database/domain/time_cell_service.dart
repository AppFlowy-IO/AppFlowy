import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/cell_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/time_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:fixnum/fixnum.dart';

final class TimeCellBackendService {
  TimeCellBackendService({
    required String viewId,
    required String fieldId,
    required String rowId,
  }) : cellId = CellIdPB.create()
          ..viewId = viewId
          ..fieldId = fieldId
          ..rowId = rowId;

  final CellIdPB cellId;

  Future<FlowyResult<void, FlowyError>> addTimeTrack(
    int fromTimestamp,
    int duration,
  ) {
    final payload = TimeCellChangesetPB.create()..cellId = cellId;
    payload.addTimeTrackings.add(
      TimeTrackPB(
        fromTimestamp: Int64(fromTimestamp),
        toTimestamp: Int64(fromTimestamp + duration),
      ),
    );

    return DatabaseEventUpdateTimeCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> updateTimeTrack(
    String id,
    int fromTimestamp,
    int duration,
  ) {
    final payload = TimeCellChangesetPB.create()..cellId = cellId;
    payload.updateTimeTrackings.add(
      TimeTrackPB(
        id: id,
        fromTimestamp: Int64(fromTimestamp),
        toTimestamp: Int64(fromTimestamp + duration),
      ),
    );

    return DatabaseEventUpdateTimeCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> deleteTimeTrack(String id) {
    final payload = TimeCellChangesetPB.create()..cellId = cellId;
    payload.deleteTimeTrackingIds.add(id);

    return DatabaseEventUpdateTimeCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> updateTime(int time) {
    final payload = TimeCellChangesetPB.create()
      ..cellId = cellId
      ..time = Int64(time);

    return DatabaseEventUpdateTimeCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> updateTimer(int timerStart) {
    final payload = TimeCellChangesetPB.create()
      ..cellId = cellId
      ..timerStart = Int64(timerStart);

    return DatabaseEventUpdateTimeCell(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> startTracking(int fromTimestamp) {
    final payload = TimeCellChangesetPB.create()..cellId = cellId;
    payload.addTimeTrackings.add(
      TimeTrackPB(fromTimestamp: Int64(fromTimestamp)),
    );

    return DatabaseEventUpdateTimeCell(payload).send();
  }
}
