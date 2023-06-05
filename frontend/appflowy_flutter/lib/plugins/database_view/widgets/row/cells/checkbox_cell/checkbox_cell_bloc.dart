import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'checkbox_cell_bloc.freezed.dart';

class CheckboxCellBloc extends Bloc<CheckboxCellEvent, CheckboxCellState> {
  final CheckboxCellController cellController;
  void Function()? _onCellChangedFn;

  CheckboxCellBloc({
    required final CellBackendService service,
    required this.cellController,
  }) : super(CheckboxCellState.initial(cellController)) {
    on<CheckboxCellEvent>(
      (final event, final emit) async {
        await event.when(
          initial: () {
            _startListening();
          },
          select: () async {
            cellController.saveCellData(!state.isSelected ? "Yes" : "No");
          },
          didReceiveCellUpdate: (final cellData) {
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

    await cellController.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellController.startListening(
      onCellChanged: ((final cellData) {
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
  const factory CheckboxCellEvent.didReceiveCellUpdate(final String? cellData) =
      _DidReceiveCellUpdate;
}

@freezed
class CheckboxCellState with _$CheckboxCellState {
  const factory CheckboxCellState({
    required final bool isSelected,
  }) = _CheckboxCellState;

  factory CheckboxCellState.initial(final TextCellController context) {
    return CheckboxCellState(isSelected: _isSelected(context.getCellData()));
  }
}

bool _isSelected(final String? cellData) {
  return cellData == "Yes";
}
