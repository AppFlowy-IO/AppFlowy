import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_cell_bloc.freezed.dart';

class TextCellBloc extends Bloc<TextCellEvent, TextCellState> {
  TextCellBloc({required this.cellController})
      : super(TextCellState.initial(cellController)) {
    _dispatch();
  }

  final TextCellController cellController;
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
    on<TextCellEvent>(
      (event, emit) {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveCellUpdate: (String content) {
            emit(state.copyWith(content: content));
          },
          didUpdateEmoji: (String emoji) {
            emit(state.copyWith(emoji: emoji));
          },
          updateText: (String text) {
            if (state.content != text) {
              cellController.saveCellData(text, debounce: true);
            }
          },
          enableEdit: (bool enabled) {
            emit(state.copyWith(enableEdit: enabled));
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (cellContent) {
        if (!isClosed) {
          add(TextCellEvent.didReceiveCellUpdate(cellContent ?? ""));
        }
      },
      onRowMetaChanged: () {
        if (!isClosed && cellController.fieldInfo.isPrimary) {
          add(TextCellEvent.didUpdateEmoji(cellController.icon ?? ""));
        }
      },
    );
  }
}

@freezed
class TextCellEvent with _$TextCellEvent {
  const factory TextCellEvent.initial() = _InitialCell;
  const factory TextCellEvent.didReceiveCellUpdate(String cellContent) =
      _DidReceiveCellUpdate;
  const factory TextCellEvent.updateText(String text) = _UpdateText;
  const factory TextCellEvent.enableEdit(bool enabled) = _EnableEdit;
  const factory TextCellEvent.didUpdateEmoji(String emoji) = _UpdateEmoji;
}

@freezed
class TextCellState with _$TextCellState {
  const factory TextCellState({
    required String content,
    required String emoji,
    required bool enableEdit,
  }) = _TextCellState;

  factory TextCellState.initial(TextCellController cellController) =>
      TextCellState(
        content: cellController.getCellData() ?? "",
        emoji:
            cellController.fieldInfo.isPrimary ? cellController.icon ?? "" : "",
        enableEdit: false,
      );
}
