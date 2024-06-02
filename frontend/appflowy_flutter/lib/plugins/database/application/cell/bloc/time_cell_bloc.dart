import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/util/time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

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
          didReceiveCellUpdate: (content) {
            emit(
              state.copyWith(
                content:
                    content != null ? formatTime(content.time.toInt()) : "",
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
            text = parseTime(text)?.toString() ?? text;
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
      onCellChanged: (cellContent) {
        if (!isClosed) {
          add(TimeCellEvent.didReceiveCellUpdate(cellContent));
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
    required bool wrap,
  }) = _TimeCellState;

  factory TimeCellState.initial(TimeCellController cellController) {
    final wrap = cellController.fieldInfo.wrapCellContent;
    final cellData = cellController.getCellData();
    return TimeCellState(
      content: cellData != null ? formatTime(cellData.time.toInt()) : "",
      wrap: wrap ?? true,
    );
  }
}
