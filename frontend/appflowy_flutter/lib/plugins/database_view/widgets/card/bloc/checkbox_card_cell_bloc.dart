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
      (final event, final emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          didReceiveCellUpdate: (final cellData) {
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
      onCellChanged: ((final cellContent) {
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
  const factory CheckboxCardCellEvent.didReceiveCellUpdate(final String cellContent) =
      _DidReceiveCellUpdate;
}

@freezed
class CheckboxCardCellState with _$CheckboxCardCellState {
  const factory CheckboxCardCellState({
    required final bool isSelected,
  }) = _CheckboxCellState;

  factory CheckboxCardCellState.initial(final TextCellController context) {
    return CheckboxCardCellState(
      isSelected: _isSelected(context.getCellData()),
    );
  }
}

bool _isSelected(final String? cellData) {
  return cellData == "Yes";
}
