import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:collection/collection.dart';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/time_entities.pb.dart';
import 'package:appflowy/plugins/database/domain/time_cell_service.dart';

part 'time_cell_editor_bloc.freezed.dart';

class TimeCellEditorBloc
    extends Bloc<TimeCellEditorEvent, TimeCellEditorState> {
  TimeCellEditorBloc({
    required this.cellController,
  })  : _timeCellBackendService = TimeCellBackendService(
          viewId: cellController.viewId,
          fieldId: cellController.fieldId,
          rowId: cellController.rowId,
        ),
        super(TimeCellEditorState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final TimeCellBackendService _timeCellBackendService;
  final TimeCellController cellController;
  void Function()? _onCellChangedFn;

  void _dispatch() {
    on<TimeCellEditorEvent>(
      (event, emit) async {
        await event.when(
          didReceiveCellUpdate: (TimeCellDataPB? cellData) {
            emit(
              state.copyWith(
                timeTracks: cellData?.timeTracks ?? [],
                time: cellData?.time.toInt(),
                timerStart: cellData?.timerStart.toInt(),
              ),
            );
          },
          addTimeTrack: (DateTime date, int duration) async {
            final fromTimestamp = date.millisecondsSinceEpoch ~/ 1000;

            await _timeCellBackendService.addTimeTrack(fromTimestamp, duration);
          },
          deleteTimeTrack: (String id) async {
            await _timeCellBackendService.deleteTimeTrack(id);
          },
          updateTimeTrack: (String id, DateTime date, int duration) async {
            final fromTimestamp = date.millisecondsSinceEpoch ~/ 1000;

            await _timeCellBackendService.updateTimeTrack(
              id,
              fromTimestamp,
              duration,
            );
          },
          updateTime: (int time) async {
            await _timeCellBackendService.updateTime(time);
          },
          updateTimer: (int time) async {
            await _timeCellBackendService.updateTimer(time);
          },
          startTracking: () async {
            final fromTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

            await _timeCellBackendService.startTracking(fromTimestamp);
          },
          stopTracking: () async {
            final timeTrack = state.trackingTimeTrack;
            if (timeTrack == null) {
              return;
            }

            final duration = DateTime.now().millisecondsSinceEpoch ~/ 1000 -
                timeTrack.fromTimestamp.toInt();

            await _timeCellBackendService.updateTimeTrack(
              timeTrack.id,
              timeTrack.fromTimestamp.toInt(),
              duration,
            );
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(
        onCellChanged: _onCellChangedFn!,
      );
    }
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (cell) {
        if (!isClosed) {
          add(TimeCellEditorEvent.didReceiveCellUpdate(cell));
        }
      },
    );
  }
}

@freezed
class TimeCellEditorEvent with _$TimeCellEditorEvent {
  // notification that cell is updated in the backend
  const factory TimeCellEditorEvent.didReceiveCellUpdate(
    TimeCellDataPB? data,
  ) = _DidReceiveCellUpdate;

  const factory TimeCellEditorEvent.addTimeTrack(DateTime date, int duration) =
      _AddTimeTrack;

  const factory TimeCellEditorEvent.deleteTimeTrack(String id) =
      _deleteTimeTrack;

  const factory TimeCellEditorEvent.updateTimeTrack(
    String id,
    DateTime date,
    int duration,
  ) = _updateTimeTrack;

  const factory TimeCellEditorEvent.updateTime(int time) = _updateTime;

  const factory TimeCellEditorEvent.updateTimer(int time) = _updateTimer;

  const factory TimeCellEditorEvent.startTracking() = _startTracking;

  const factory TimeCellEditorEvent.stopTracking() = _stopTracking;
}

@freezed
class TimeCellEditorState with _$TimeCellEditorState {
  const TimeCellEditorState._();

  const factory TimeCellEditorState({
    required int? time,
    required int? timerStart,
    required List<TimeTrackPB> timeTracks,
  }) = _TimeCellEditorState;

  factory TimeCellEditorState.initial(
    TimeCellController controller,
  ) {
    final cellData = controller.getCellData();

    return TimeCellEditorState(
      time: cellData?.time.toInt(),
      timerStart: cellData?.timerStart.toInt(),
      timeTracks: cellData?.timeTracks ?? [],
    );
  }

  bool get isTracking => timeTracks.any((tt) => tt.toTimestamp == 0);

  TimeTrackPB? get trackingTimeTrack =>
      timeTracks.firstWhereOrNull((tt) => tt.toTimestamp == 0);
}
