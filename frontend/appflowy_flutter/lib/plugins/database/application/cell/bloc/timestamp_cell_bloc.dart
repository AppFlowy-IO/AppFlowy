import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/timestamp_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'timestamp_cell_bloc.freezed.dart';

class TimestampCellBloc extends Bloc<TimestampCellEvent, TimestampCellState> {
  TimestampCellBloc({required this.cellController})
      : super(TimestampCellState.initial(cellController)) {
    _dispatch();
  }

  final TimestampCellController cellController;
  void Function()? _onCellChangedFn;

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    await cellController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<TimestampCellEvent>(
      (event, emit) async {
        event.when(
          initial: () => _startListening(),
          didReceiveCellUpdate: (TimestampCellDataPB? cellData) {
            emit(
              state.copyWith(
                data: cellData,
                dateStr: cellData?.dateTime ?? "",
              ),
            );
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
    );
  }
}

@freezed
class TimestampCellEvent with _$TimestampCellEvent {
  const factory TimestampCellEvent.initial() = _InitialCell;
  const factory TimestampCellEvent.didReceiveCellUpdate(
    TimestampCellDataPB? data,
  ) = _DidReceiveCellUpdate;
}

@freezed
class TimestampCellState with _$TimestampCellState {
  const factory TimestampCellState({
    required TimestampCellDataPB? data,
    required String dateStr,
    required FieldInfo fieldInfo,
  }) = _TimestampCellState;

  factory TimestampCellState.initial(TimestampCellController context) {
    final cellData = context.getCellData();

    return TimestampCellState(
      fieldInfo: context.fieldInfo,
      data: cellData,
      dateStr: cellData?.dateTime ?? "",
    );
  }
}
