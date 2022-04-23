import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Cell;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'checkbox_cell_bloc.freezed.dart';

class CheckboxCellBloc extends Bloc<CheckboxCellEvent, CheckboxCellState> {
  final GridDefaultCellContext cellContext;

  CheckboxCellBloc({
    required CellService service,
    required this.cellContext,
  }) : super(CheckboxCellState.initial(cellContext)) {
    on<CheckboxCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) {
            _startListening();
          },
          select: (_Selected value) async {
            _updateCellData();
          },
          didReceiveCellUpdate: (_DidReceiveCellUpdate value) {
            emit(state.copyWith(isSelected: _isSelected(value.cell)));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    cellContext.dispose();
    return super.close();
  }

  void _startListening() {
    cellContext.onCellChanged((cell) {
      if (!isClosed) {
        add(CheckboxCellEvent.didReceiveCellUpdate(cell));
      }
    });
  }

  void _updateCellData() {
    cellContext.saveCellData(!state.isSelected ? "Yes" : "No");
  }
}

@freezed
class CheckboxCellEvent with _$CheckboxCellEvent {
  const factory CheckboxCellEvent.initial() = _Initial;
  const factory CheckboxCellEvent.select() = _Selected;
  const factory CheckboxCellEvent.didReceiveCellUpdate(Cell cell) = _DidReceiveCellUpdate;
}

@freezed
class CheckboxCellState with _$CheckboxCellState {
  const factory CheckboxCellState({
    required bool isSelected,
  }) = _CheckboxCellState;

  factory CheckboxCellState.initial(GridCellContext context) {
    return CheckboxCellState(isSelected: _isSelected(context.getCellData()));
  }
}

bool _isSelected(Cell? cell) {
  final content = cell?.content ?? "";
  return content == "Yes";
}
