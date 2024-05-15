import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/util/timer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

part 'timer_cell_bloc.freezed.dart';

class TimerCellBloc extends Bloc<TimerCellEvent, TimerCellState> {
  TimerCellBloc({
    required this.cellController,
  }) : super(TimerCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final TimerCellController cellController;
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
    on<TimerCellEvent>(
      (event, emit) async {
        await event.when(
          didReceiveCellUpdate: (content) {
            emit(state.copyWith(content: content?.timer ?? ""));
          },
          didUpdateField: (fieldInfo) {
            final wrap = fieldInfo.wrapCellContent;
            if (wrap != null) {
              emit(state.copyWith(wrap: wrap));
            }
          },
          updateCell: (text) async {
            text = parseTimer(text)?.toString() ?? "";
            print(text);
            if (state.content != text) {
              emit(state.copyWith(content: text));
              await cellController.saveCellData(text);

              // If the input content is "abc" that can't parsered as number
              // then the data stored in the backend will be an empty string.
              // So for every cell data that will be formatted in the backend.
              // It needs to get the formatted data after saving.
              add(
                TimerCellEvent.didReceiveCellUpdate(
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
      onCellChanged: (cellContent) {
        if (!isClosed) {
          add(TimerCellEvent.didReceiveCellUpdate(cellContent));
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(TimerCellEvent.didUpdateField(fieldInfo));
    }
  }
}

@freezed
class TimerCellEvent with _$TimerCellEvent {
  const factory TimerCellEvent.didReceiveCellUpdate(TimerCellDataPB? cell) =
      _DidReceiveCellUpdate;
  const factory TimerCellEvent.didUpdateField(FieldInfo fieldInfo) =
      _DidUpdateField;
  const factory TimerCellEvent.updateCell(String text) = _UpdateCell;
}

@freezed
class TimerCellState with _$TimerCellState {
  const factory TimerCellState({
    required String content,
    required bool wrap,
  }) = _TimerCellState;

  factory TimerCellState.initial(TimerCellController cellController) {
    final wrap = cellController.fieldInfo.wrapCellContent;
    return TimerCellState(
      content: cellController.getCellData()?.timer ?? "",
      wrap: wrap ?? true,
    );
  }
}
