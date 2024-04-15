import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'date_cell_bloc.freezed.dart';

class DateCellBloc extends Bloc<DateCellEvent, DateCellState> {
  DateCellBloc({required this.cellController})
      : super(DateCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final DateCellController cellController;
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
    on<DateCellEvent>(
      (event, emit) async {
        event.when(
          didReceiveCellUpdate: (DateCellDataPB? cellData) {
            emit(
              state.copyWith(
                data: cellData,
                dateStr: _dateStrFromCellData(cellData),
              ),
            );
          },
          didUpdateField: (fieldInfo) {
            emit(state.copyWith(fieldInfo: fieldInfo));
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (data) {
        if (!isClosed) {
          add(DateCellEvent.didReceiveCellUpdate(data));
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(DateCellEvent.didUpdateField(fieldInfo));
    }
  }
}

@freezed
class DateCellEvent with _$DateCellEvent {
  const factory DateCellEvent.didReceiveCellUpdate(DateCellDataPB? data) =
      _DidReceiveCellUpdate;
  const factory DateCellEvent.didUpdateField(FieldInfo fieldInfo) =
      _DidUpdateField;
}

@freezed
class DateCellState with _$DateCellState {
  const factory DateCellState({
    required DateCellDataPB? data,
    required String dateStr,
    required FieldInfo fieldInfo,
  }) = _DateCellState;

  factory DateCellState.initial(DateCellController context) {
    final cellData = context.getCellData();

    return DateCellState(
      fieldInfo: context.fieldInfo,
      data: cellData,
      dateStr: _dateStrFromCellData(cellData),
    );
  }
}

String _dateStrFromCellData(DateCellDataPB? cellData) {
  if (cellData == null || !cellData.hasTimestamp()) {
    return "";
  }

  String dateStr = "";
  if (cellData.isRange) {
    if (cellData.includeTime) {
      dateStr =
          "${cellData.date} ${cellData.time} → ${cellData.endDate} ${cellData.endTime}";
    } else {
      dateStr = "${cellData.date} → ${cellData.endDate}";
    }
  } else {
    if (cellData.includeTime) {
      dateStr = "${cellData.date} ${cellData.time}";
    } else {
      dateStr = cellData.date;
    }
  }
  return dateStr.trim();
}
