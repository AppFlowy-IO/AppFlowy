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
      (final event, final emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          didReceiveCellUpdate: (final content) {
            emit(state.copyWith(content: content));
          },
          updateText: (final text) {
            if (text != state.content) {
              cellController.saveCellData(text);
              emit(state.copyWith(content: text));
            }
          },
          enableEdit: (final bool enabled) {
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
      onCellChanged: ((final cellContent) {
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
  const factory TextCardCellEvent.updateText(final String text) = _UpdateContent;
  const factory TextCardCellEvent.enableEdit(final bool enabled) = _EnableEdit;
  const factory TextCardCellEvent.didReceiveCellUpdate(final String cellContent) =
      _DidReceiveCellUpdate;
}

@freezed
class TextCardCellState with _$TextCardCellState {
  const factory TextCardCellState({
    required final String content,
    required final bool enableEdit,
  }) = _TextCardCellState;

  factory TextCardCellState.initial(final TextCellController context) =>
      TextCardCellState(
        content: context.getCellData() ?? "",
        enableEdit: false,
      );
}
