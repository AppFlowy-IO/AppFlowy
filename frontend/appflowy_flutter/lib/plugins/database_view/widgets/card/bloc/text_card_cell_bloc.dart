import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'text_card_cell_bloc.freezed.dart';

class TextCardCellBloc extends Bloc<TextCardCellEvent, TextCardCellState> {
  final TextCellController cellController;
  void Function()? _onCellChangedFn;
  TextCardCellBloc({
    required this.cellController,
  }) : super(TextCardCellState.initial(cellController)) {
    on<TextCardCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          didReceiveCellUpdate: (content) {
            emit(state.copyWith(content: content));
          },
          updateText: (text) {
            if (text != state.content) {
              cellController.saveCellData(text);
              emit(state.copyWith(content: text));
            }
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
          add(TextCardCellEvent.didReceiveCellUpdate(cellContent ?? ""));
        }
      }),
    );
  }
}

@freezed
class TextCardCellEvent with _$TextCardCellEvent {
  const factory TextCardCellEvent.initial() = _InitialCell;
  const factory TextCardCellEvent.updateText(String text) = _UpdateContent;
  const factory TextCardCellEvent.enableEdit(bool enabled) = _EnableEdit;
  const factory TextCardCellEvent.didReceiveCellUpdate(String cellContent) =
      _DidReceiveCellUpdate;
}

@freezed
class TextCardCellState with _$TextCardCellState {
  const factory TextCardCellState({
    required String content,
    required bool enableEdit,
  }) = _TextCardCellState;

  factory TextCardCellState.initial(TextCellController context) =>
      TextCardCellState(
        content: context.getCellData() ?? "",
        enableEdit: false,
      );
}
