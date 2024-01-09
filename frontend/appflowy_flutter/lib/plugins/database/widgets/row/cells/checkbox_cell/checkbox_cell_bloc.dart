import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkbox_cell_bloc.freezed.dart';

class CheckboxCellBloc extends Bloc<CheckboxCellEvent, CheckboxCellState> {
  final CheckboxCellController cellController;
  void Function()? _onCellChangedFn;

  CheckboxCellBloc({
    required this.cellController,
  }) : super(CheckboxCellState.initial(cellController)) {
    on<CheckboxCellEvent>(
      (event, emit) {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveCellUpdate: (cellData) {
            emit(state.copyWith(isSelected: _isSelected(cellData)));
          },
          select: () {
            cellController.saveCellData(state.isSelected ? "No" : "Yes");
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
    _onCellChangedFn = cellController.addListener(
      onCellChanged: ((cellData) {
        if (!isClosed) {
          add(CheckboxCellEvent.didReceiveCellUpdate(cellData));
        }
      }),
    );
  }
}

@freezed
class CheckboxCellEvent with _$CheckboxCellEvent {
  const factory CheckboxCellEvent.initial() = _Initial;
  const factory CheckboxCellEvent.select() = _Selected;
  const factory CheckboxCellEvent.didReceiveCellUpdate(String? cellData) =
      _DidReceiveCellUpdate;
}

@freezed
class CheckboxCellState with _$CheckboxCellState {
  const factory CheckboxCellState({
    required bool isSelected,
  }) = _CheckboxCellState;

  factory CheckboxCellState.initial(TextCellController context) {
    return CheckboxCellState(isSelected: _isSelected(context.getCellData()));
  }
}

bool _isSelected(String? cellData) {
  // The backend use "Yes" and "No" to represent the checkbox cell data.
  return cellData == "Yes";
}
