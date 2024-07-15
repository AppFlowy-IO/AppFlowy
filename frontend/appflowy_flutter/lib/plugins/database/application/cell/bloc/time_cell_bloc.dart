import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';

part 'time_cell_bloc.freezed.dart';

class TimeCellBloc extends Bloc<TimeCellEvent, TimeCellState> {
  TimeCellBloc({
    required this.cellController,
  }) : super(TimeCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

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
                timeType: typeOption.timeType,
                precision: typeOption.precision,
              ),
            );
          },
          didUpdateField: (fieldInfo) {
            final wrap = fieldInfo.wrapCellContent;
            if (wrap != null) {
              emit(state.copyWith(wrap: wrap));
            }
          },
          updateCell: (text) async {
            text =
                parseTimeToSeconds(text, state.precision)?.toString() ?? text;
            if (state.content != text) {
              emit(state.copyWith(content: text));
              await cellController.saveCellData(text);

              // If the input content is "abc" that can't parsered as number
              // then the data stored in the backend will be an empty string.
              // So for every cell data that will be formatted in the backend.
              // It needs to get the formatted data after saving.
              add(
                TimeCellEvent.didReceiveCellUpdate(
                  cellController.getCellData(),
                ),
              );
            }
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
  const factory TimeCellEvent.updateCell(String text) = _UpdateCell;
}

@freezed
class TimeCellState with _$TimeCellState {
  const factory TimeCellState({
    required String content,
    required TimePrecisionPB precision,
    required TimeTypePB timeType,
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
      precision: typeOption.precision,
      timeType: typeOption.timeType,
      wrap: wrap ?? true,
    );
  }
}

String formatTimeSeconds(
  int seconds, [
  TimePrecisionPB precision = TimePrecisionPB.Seconds,
]) {
  if (precision == TimePrecisionPB.Minutes) {
    seconds ~/= 60;
  }
  return formatTime(seconds, precision);
}

String formatTime(
  int time, [
  TimePrecisionPB precision = TimePrecisionPB.Seconds,
]) {
  if (precision == TimePrecisionPB.Minutes) {
    time *= 60;
  }
  final (hours, minutes, seconds) = splitTimeToHMS(time);

  return precision == TimePrecisionPB.Seconds
      ? formatTimeFromHMS(hours, minutes, seconds)
      : formatTimeFromHMS(hours, minutes);
}

(int, int, int) splitTimeToHMS(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds - hours * 3600) ~/ 60;
  final remainingSeconds = seconds - hours * 3600 - minutes * 60;

  return (hours, minutes, remainingSeconds);
}

String formatTimeFromHMS(int hours, int minutes, [int? seconds]) {
  final res = [];
  if (hours != 0) {
    res.add("${hours}h");
  }
  res.add("${minutes}m");
  if (seconds != null) {
    res.add("${seconds}s");
  }

  return res.join(" ");
}

final RegExp _timeStrRegExp = RegExp(
  r'(?:(?<hours>\d*)h)? ?(?:(?<minutes>\d*)m)? ?(?:(?<seconds>\d*)s)?',
);

int? parseTimeToSeconds(String timeStr, TimePrecisionPB precision) {
  final int coeficient = precision == TimePrecisionPB.Seconds ? 1 : 60;

  int? res = int.tryParse(timeStr);
  if (res != null) {
    return res * coeficient;
  }

  final matches = _timeStrRegExp.firstMatch(timeStr);
  if (matches == null) {
    return null;
  }
  final hours = int.tryParse(matches.namedGroup('hours') ?? "");
  final minutes = int.tryParse(matches.namedGroup('minutes') ?? "");
  final seconds = int.tryParse(matches.namedGroup('seconds') ?? "");
  if (hours == null && minutes == null && seconds == null) {
    return null;
  }

  final expected = [];
  if (hours != null) {
    expected.add("${hours}h");
  }
  if (minutes != null) {
    expected.add("${minutes}m");
  }
  if (seconds != null) {
    expected.add("${seconds}s");
  }
  if (timeStr != expected.join(" ")) {
    return null;
  }

  res = 0;
  res += hours != null ? hours * 3600 : 0;
  res += minutes != null ? minutes * 60 : 0;
  res += seconds ?? 0;

  return res;
}
