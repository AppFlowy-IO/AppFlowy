import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/timestamp_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'timestamp_cell_bloc.freezed.dart';

class TimestampCellBloc extends Bloc<TimestampCellEvent, TimestampCellState> {
  TimestampCellBloc({
    required this.cellController,
  }) : super(TimestampCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final TimestampCellController cellController;
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
    on<TimestampCellEvent>(
      (event, emit) async {
        event.when(
          didReceiveCellUpdate: (TimestampCellDataPB? cellData) {
            emit(
              state.copyWith(
                data: cellData,
                dateStr: cellData?.dateTime ?? "",
              ),
            );
          },
          didUpdateField: (fieldInfo) {
            final wrap = fieldInfo.wrapCellContent;
            if (wrap != null) {
              emit(state.copyWith(wrap: wrap));
            }
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (data) {
        if (!isClosed) {
          add(TimestampCellEvent.didReceiveCellUpdate(data));
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(TimestampCellEvent.didUpdateField(fieldInfo));
    }
  }
}

@freezed
class TimestampCellEvent with _$TimestampCellEvent {
  const factory TimestampCellEvent.didReceiveCellUpdate(
    TimestampCellDataPB? data,
  ) = _DidReceiveCellUpdate;
  const factory TimestampCellEvent.didUpdateField(FieldInfo fieldInfo) =
      _DidUpdateField;
}

@freezed
class TimestampCellState with _$TimestampCellState {
  const factory TimestampCellState({
    required TimestampCellDataPB? data,
    required String dateStr,
    required FieldInfo fieldInfo,
    required bool wrap,
  }) = _TimestampCellState;

  factory TimestampCellState.initial(TimestampCellController cellController) {
    final cellData = cellController.getCellData();
    final wrap = cellController.fieldInfo.wrapCellContent;

    return TimestampCellState(
      fieldInfo: cellController.fieldInfo,
      data: cellData,
      dateStr: cellData?.dateTime ?? "",
      wrap: wrap ?? true,
    );
  }
}
