import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'number_cell_bloc.freezed.dart';

class NumberCellBloc extends Bloc<NumberCellEvent, NumberCellState> {
  NumberCellBloc({
    required this.cellController,
  }) : super(NumberCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final NumberCellController cellController;
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
    on<NumberCellEvent>(
      (event, emit) async {
        await event.when(
          didReceiveCellUpdate: (cellData) {
            emit(state.copyWith(content: cellData ?? ""));
          },
          didUpdateField: (fieldInfo) {
            final wrap = fieldInfo.wrapCellContent;
            if (wrap != null) {
              emit(state.copyWith(wrap: wrap));
            }
          },
          updateCell: (text) async {
            if (state.content != text) {
              emit(state.copyWith(content: text));
              await cellController.saveCellData(text);

              // If the input content is "abc" that can't parsered as number then the data stored in the backend will be an empty string.
              // So for every cell data that will be formatted in the backend.
              // It needs to get the formatted data after saving.
              add(
                NumberCellEvent.didReceiveCellUpdate(
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
          add(NumberCellEvent.didReceiveCellUpdate(cellContent));
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(NumberCellEvent.didUpdateField(fieldInfo));
    }
  }
}

@freezed
class NumberCellEvent with _$NumberCellEvent {
  const factory NumberCellEvent.didReceiveCellUpdate(String? cellContent) =
      _DidReceiveCellUpdate;
  const factory NumberCellEvent.didUpdateField(FieldInfo fieldInfo) =
      _DidUpdateField;
  const factory NumberCellEvent.updateCell(String text) = _UpdateCell;
}

@freezed
class NumberCellState with _$NumberCellState {
  const factory NumberCellState({
    required String content,
    required bool wrap,
  }) = _NumberCellState;

  factory NumberCellState.initial(TextCellController cellController) {
    final wrap = cellController.fieldInfo.wrapCellContent;
    return NumberCellState(
      content: cellController.getCellData() ?? "",
      wrap: wrap ?? true,
    );
  }
}
