import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'board_text_cell_bloc.freezed.dart';

class BoardTextCellBloc extends Bloc<BoardTextCellEvent, BoardTextCellState> {
  final GridCellController cellController;
  void Function()? _onCellChangedFn;
  BoardTextCellBloc({
    required this.cellController,
  }) : super(BoardTextCellState.initial(cellController)) {
    on<BoardTextCellEvent>(
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
    cellController.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellController.startListening(
      onCellChanged: ((cellContent) {
        if (!isClosed) {
          add(BoardTextCellEvent.didReceiveCellUpdate(cellContent ?? ""));
        }
      }),
    );
  }
}

@freezed
class BoardTextCellEvent with _$BoardTextCellEvent {
  const factory BoardTextCellEvent.initial() = _InitialCell;
  const factory BoardTextCellEvent.updateText(String text) = _UpdateContent;
  const factory BoardTextCellEvent.enableEdit(bool enabled) = _EnableEdit;
  const factory BoardTextCellEvent.didReceiveCellUpdate(String cellContent) =
      _DidReceiveCellUpdate;
}

@freezed
class BoardTextCellState with _$BoardTextCellState {
  const factory BoardTextCellState({
    required String content,
    required bool enableEdit,
  }) = _BoardTextCellState;

  factory BoardTextCellState.initial(GridCellController context) =>
      BoardTextCellState(
        content: context.getCellData() ?? "",
        enableEdit: false,
      );
}
