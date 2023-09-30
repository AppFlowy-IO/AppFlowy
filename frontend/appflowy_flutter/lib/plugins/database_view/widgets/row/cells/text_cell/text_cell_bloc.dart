import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'text_cell_bloc.freezed.dart';

class TextCellBloc extends Bloc<TextCellEvent, TextCellState> {
  final TextCellController cellController;
  void Function()? _onCellChangedFn;
  TextCellBloc({
    required this.cellController,
  }) : super(TextCellState.initial(cellController)) {
    on<TextCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          updateText: (text) {
            if (state.content != text) {
              cellController.saveCellData(text);
              emit(state.copyWith(content: text));
            }
          },
          didReceiveCellUpdate: (content) {
            emit(state.copyWith(content: content));
          },
          didUpdateEmoji: (String emoji) {
            emit(state.copyWith(emoji: emoji));
          },
          enableEdit: (bool enabled) {
            emit(state.copyWith(enableEdit: enabled));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    await cellController.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellController.startListening(
      onCellChanged: ((cellContent) {
        if (!isClosed) {
          add(TextCellEvent.didReceiveCellUpdate(cellContent ?? ""));
        }
      }),
      onRowMetaChanged: () {
        if (!isClosed) {
          add(TextCellEvent.didUpdateEmoji(cellController.emoji ?? ""));
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

  factory TextCellState.initial(TextCellController context) => TextCellState(
        content: context.getCellData() ?? "",
        emoji: context.emoji ?? "",
        enableEdit: false,
      );
}
