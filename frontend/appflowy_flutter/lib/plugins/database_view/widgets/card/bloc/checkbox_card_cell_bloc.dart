import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import '../../../application/cell/cell_controller_builder.dart';

part 'checkbox_card_cell_bloc.freezed.dart';

class CheckboxCardCellBloc
    extends Bloc<CheckboxCardCellEvent, CheckboxCardCellState> {
  final CheckboxCellController cellController;
  void Function()? _onCellChangedFn;
  CheckboxCardCellBloc({
    required this.cellController,
  }) : super(CheckboxCardCellState.initial(cellController)) {
    on<CheckboxCardCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          didReceiveCellUpdate: (cellData) {
            emit(state.copyWith(isSelected: _isSelected(cellData)));
          },
          select: () async {
            cellController.saveCellData(!state.isSelected ? "Yes" : "No");
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
          add(CheckboxCardCellEvent.didReceiveCellUpdate(cellContent ?? ""));
        }
      }),
    );
  }
}

@freezed
class CheckboxCardCellEvent with _$CheckboxCardCellEvent {
  const factory CheckboxCardCellEvent.initial() = _InitialCell;
  const factory CheckboxCardCellEvent.select() = _Selected;
  const factory CheckboxCardCellEvent.didReceiveCellUpdate(String cellContent) =
      _DidReceiveCellUpdate;
}

@freezed
class CheckboxCardCellState with _$CheckboxCardCellState {
  const factory CheckboxCardCellState({
    required bool isSelected,
  }) = _CheckboxCellState;

  factory CheckboxCardCellState.initial(TextCellController context) {
    return CheckboxCardCellState(
      isSelected: _isSelected(context.getCellData()),
    );
  }
}

bool _isSelected(String? cellData) {
  // The backend use "Yes" and "No" to represent the checkbox cell data.
  return cellData == "Yes";
}
