import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service/cell_service.dart';

part 'checkbox_cell_bloc.freezed.dart';

class CheckboxCellBloc extends Bloc<CheckboxCellEvent, CheckboxCellState> {
  final GridCheckboxCellController cellController;
  void Function()? _onCellChangedFn;

  CheckboxCellBloc({
    required CellService service,
    required this.cellController,
  }) : super(CheckboxCellState.initial(cellController)) {
    on<CheckboxCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () {
            _startListening();
          },
          select: () async {
            _updateCellData();
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
    _onCellChangedFn =
        cellController.startListening(onCellChanged: ((cellData) {
      if (!isClosed) {
        add(CheckboxCellEvent.didReceiveCellUpdate(cellData));
      }
    }));
  }

  void _updateCellData() {
    cellController.saveCellData(!state.isSelected ? "Yes" : "No");
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

  factory CheckboxCellState.initial(GridCellController context) {
    return CheckboxCellState(isSelected: _isSelected(context.getCellData()));
  }
}

bool _isSelected(String? cellData) {
  return cellData == "Yes";
}
