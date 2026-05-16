import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'translate_cell_bloc.freezed.dart';

class TranslateCellBloc extends Bloc<TranslateCellEvent, TranslateCellState> {
  TranslateCellBloc({
    required this.cellController,
  }) : super(TranslateCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final TranslateCellController cellController;
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
    on<TranslateCellEvent>(
      (event, emit) async {
        await event.when(
          didReceiveCellUpdate: (cellData) {
            emit(
              state.copyWith(content: cellData ?? ""),
            );
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
                TranslateCellEvent.didReceiveCellUpdate(
                  cellController.getCellData() ?? "",
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
          add(
            TranslateCellEvent.didReceiveCellUpdate(cellContent ?? ""),
          );
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(TranslateCellEvent.didUpdateField(fieldInfo));
    }
  }
}

@freezed
class TranslateCellEvent with _$TranslateCellEvent {
  const factory TranslateCellEvent.didReceiveCellUpdate(String? cellContent) =
      _DidReceiveCellUpdate;
  const factory TranslateCellEvent.didUpdateField(FieldInfo fieldInfo) =
      _DidUpdateField;
  const factory TranslateCellEvent.updateCell(String text) = _UpdateCell;
}

@freezed
class TranslateCellState with _$TranslateCellState {
  const factory TranslateCellState({
    required String content,
    required bool wrap,
  }) = _TranslateCellState;

  factory TranslateCellState.initial(TranslateCellController cellController) {
    final wrap = cellController.fieldInfo.wrapCellContent;
    return TranslateCellState(
      content: cellController.getCellData() ?? "",
      wrap: wrap ?? true,
    );
  }
}
