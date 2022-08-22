import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'board_checkbox_cell_bloc.freezed.dart';

class BoardCheckboxCellBloc
    extends Bloc<BoardCheckboxCellEvent, BoardCheckboxCellState> {
  final GridCheckboxCellController cellController;
  void Function()? _onCellChangedFn;
  BoardCheckboxCellBloc({
    required this.cellController,
  }) : super(BoardCheckboxCellState.initial(cellController)) {
    on<BoardCheckboxCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          didReceiveCellUpdate: (cellData) {
            emit(state.copyWith(isSelected: _isSelected(cellData)));
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
          add(BoardCheckboxCellEvent.didReceiveCellUpdate(cellContent ?? ""));
        }
      }),
    );
  }
}

@freezed
class BoardCheckboxCellEvent with _$BoardCheckboxCellEvent {
  const factory BoardCheckboxCellEvent.initial() = _InitialCell;
  const factory BoardCheckboxCellEvent.didReceiveCellUpdate(
      String cellContent) = _DidReceiveCellUpdate;
}

@freezed
class BoardCheckboxCellState with _$BoardCheckboxCellState {
  const factory BoardCheckboxCellState({
    required bool isSelected,
  }) = _CheckboxCellState;

  factory BoardCheckboxCellState.initial(GridCellController context) {
    return BoardCheckboxCellState(
        isSelected: _isSelected(context.getCellData()));
  }
}

bool _isSelected(String? cellData) {
  return cellData == "Yes";
}
