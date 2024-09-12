import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database/domain/time_cell_service.dart';
import 'package:appflowy/util/time.dart';

part 'time_cell_bloc.freezed.dart';

class TimeCellBloc extends Bloc<TimeCellEvent, TimeCellState> {
  TimeCellBloc({
    required this.cellController,
  })  : _timeCellBackendService = TimeCellBackendService(
          viewId: cellController.viewId,
          fieldId: cellController.fieldId,
          rowId: cellController.rowId,
        ),
        super(TimeCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final TimeCellBackendService _timeCellBackendService;
  final TimeCellController cellController;
  void Function()? _onCellChangedFn;

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(
        onCellChanged: _onCellChangedFn!,
        onFieldChanged: _onFieldChangedListener,
      );
    }
    await cellController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<TimeCellEvent>(
      (event, emit) async {
        await event.when(
          didReceiveCellUpdate: (cellData) {
            final typeOption = cellController
                .getTypeOption<TimeTypeOptionPB>(TimeTypeOptionDataParser());

            emit(
              state.copyWith(
                content: cellData != null
                    ? formatTime(cellData.time.toInt(), typeOption.precision)
                    : "",
                timeTracks: cellData?.timeTracks ?? [],
                timeType: typeOption.timeType,
                precision: typeOption.precision,
              ),
            );
          },
          didUpdateField: (fieldInfo) {
            final wrap = fieldInfo.wrapCellContent;
            final typeOption = cellController
                .getTypeOption<TimeTypeOptionPB>(TimeTypeOptionDataParser());

            if (wrap != state.wrap ||
                state.timeType != typeOption.timeType ||
                state.precision != typeOption.precision) {
              emit(
                state.copyWith(
                  wrap: wrap ?? true,
                  timeType: typeOption.timeType,
                  precision: typeOption.precision,
                ),
              );
            }
          },
          updateTime: (String text) async {
            final time = parseTimeToSeconds(text, state.precision);
            if (state.content != text) {
              await _timeCellBackendService.updateTime(time ?? 0);
            }
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

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (cellData) {
        if (!isClosed) {
          add(TimeCellEvent.didReceiveCellUpdate(cellData));
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(TimeCellEvent.didUpdateField(fieldInfo));
    }
  }
}

@freezed
class TimeCellEvent with _$TimeCellEvent {
  const factory TimeCellEvent.didReceiveCellUpdate(TimeCellDataPB? cell) =
      _DidReceiveCellUpdate;
  const factory TimeCellEvent.didUpdateField(FieldInfo fieldInfo) =
      _DidUpdateField;
  const factory TimeCellEvent.updateTime(String text) = _UpdateCell;

  const factory TimeCellEvent.startTracking() = _startTracking;

  const factory TimeCellEvent.stopTracking() = _stopTracking;
}

@freezed
class TimeCellState with _$TimeCellState {
  const TimeCellState._();

  const factory TimeCellState({
    required String content,
    required TimePrecisionPB precision,
    required TimeTypePB timeType,
    required List<TimeTrackPB> timeTracks,
    required bool wrap,
  }) = _TimeCellState;

  factory TimeCellState.initial(TimeCellController cellController) {
    final cellData = cellController.getCellData();
    final typeOption = cellController
        .getTypeOption<TimeTypeOptionPB>(TimeTypeOptionDataParser());
    final wrap = cellController.fieldInfo.wrapCellContent;

    return TimeCellState(
      content: cellData != null
          ? formatTime(cellData.time.toInt(), typeOption.precision)
          : "",
      timeTracks: cellData?.timeTracks ?? [],
      precision: typeOption.precision,
      timeType: typeOption.timeType,
      wrap: wrap ?? true,
    );
  }

  bool get isTracking => timeTracks.any((tt) => tt.toTimestamp == 0);

  TimeTrackPB? get trackingTimeTrack =>
      timeTracks.firstWhereOrNull((tt) => tt.toTimestamp == 0);
}
