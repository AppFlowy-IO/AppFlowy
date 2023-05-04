import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'number_cell_bloc.freezed.dart';

//
class NumberCellBloc extends Bloc<NumberCellEvent, NumberCellState> {
  final NumberCellController cellController;
  void Function()? _onCellChangedFn;

  NumberCellBloc({
    required this.cellController,
  }) : super(NumberCellState.initial(cellController)) {
    on<NumberCellEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveCellUpdate: (cellContent) {
            emit(state.copyWith(cellContent: cellContent ?? ""));
          },
          updateCell: (text) async {
            if (state.cellContent != text) {
              emit(state.copyWith(cellContent: text));
              await cellController.saveCellData(text);

              // If the input content is "abc" that can't parsered as number then the data stored in the backend will be an empty string.
              // So for every cell data that will be formatted in the backend.
              // It needs to get the formatted data after saving.
              add(
                NumberCellEvent.didReceiveCellUpdate(
                  cellController.getCellData(),
                ),
              );
            }
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
          add(NumberCellEvent.didReceiveCellUpdate(cellContent));
        }
      }),
    );
  }
}

@freezed
class NumberCellEvent with _$NumberCellEvent {
  const factory NumberCellEvent.initial() = _Initial;
  const factory NumberCellEvent.updateCell(String text) = _UpdateCell;
  const factory NumberCellEvent.didReceiveCellUpdate(String? cellContent) =
      _DidReceiveCellUpdate;
}

@freezed
class NumberCellState with _$NumberCellState {
  const factory NumberCellState({
    required String cellContent,
  }) = _NumberCellState;

  factory NumberCellState.initial(TextCellController context) {
    return NumberCellState(
      cellContent: context.getCellData() ?? "",
    );
  }
}
