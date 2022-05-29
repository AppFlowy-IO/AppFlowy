import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service/cell_service.dart';

part 'text_cell_bloc.freezed.dart';

class TextCellBloc extends Bloc<TextCellEvent, TextCellState> {
  final GridCellContext cellContext;
  void Function()? _onCellChangedFn;
  TextCellBloc({
    required this.cellContext,
  }) : super(TextCellState.initial(cellContext)) {
    on<TextCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          updateText: (text) {
            cellContext.saveCellData(text);
            emit(state.copyWith(content: text));
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
      cellContext.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    cellContext.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellContext.startListening(
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
  const factory TextCellEvent.didReceiveCellUpdate(String cellContent) = _DidReceiveCellUpdate;
  const factory TextCellEvent.updateText(String text) = _UpdateText;
}

@freezed
class TextCellState with _$TextCellState {
  const factory TextCellState({
    required String content,
  }) = _TextCellState;

  factory TextCellState.initial(GridCellContext context) => TextCellState(
        content: context.getCellData() ?? "",
      );
}
