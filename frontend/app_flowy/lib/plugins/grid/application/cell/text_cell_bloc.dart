import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service/cell_service.dart';

part 'text_cell_bloc.freezed.dart';

class TextCellBloc extends Bloc<TextCellEvent, TextCellState> {
  final GridTextCellController cellController;
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
    );
  }
}

@freezed
class TextCellEvent with _$TextCellEvent {
  const factory TextCellEvent.initial() = _InitialCell;
  const factory TextCellEvent.didReceiveCellUpdate(String cellContent) =
      _DidReceiveCellUpdate;
  const factory TextCellEvent.updateText(String text) = _UpdateText;
}

@freezed
class TextCellState with _$TextCellState {
  const factory TextCellState({
    required String content,
  }) = _TextCellState;

  factory TextCellState.initial(GridTextCellController context) =>
      TextCellState(
        content: context.getCellData() ?? "",
      );
}
