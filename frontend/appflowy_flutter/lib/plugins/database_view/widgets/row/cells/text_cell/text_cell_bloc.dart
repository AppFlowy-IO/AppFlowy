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
      (final event, final emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          updateText: (final text) {
            if (state.content != text) {
              cellController.saveCellData(text);
              emit(state.copyWith(content: text));
            }
          },
          didReceiveCellUpdate: (final content) {
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
      onCellChanged: ((final cellContent) {
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
  const factory TextCellEvent.didReceiveCellUpdate(final String cellContent) =
      _DidReceiveCellUpdate;
  const factory TextCellEvent.updateText(final String text) = _UpdateText;
}

@freezed
class TextCellState with _$TextCellState {
  const factory TextCellState({
    required final String content,
  }) = _TextCellState;

  factory TextCellState.initial(final TextCellController context) => TextCellState(
        content: context.getCellData() ?? "",
      );
}
