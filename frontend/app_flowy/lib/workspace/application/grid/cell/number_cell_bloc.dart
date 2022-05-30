import 'package:flowy_sdk/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service/cell_service.dart';

part 'number_cell_bloc.freezed.dart';

class NumberCellBloc extends Bloc<NumberCellEvent, NumberCellState> {
  final GridCellContext cellContext;
  void Function()? _onCellChangedFn;

  NumberCellBloc({
    required this.cellContext,
  }) : super(NumberCellState.initial(cellContext)) {
    on<NumberCellEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
          },
          didReceiveCellUpdate: (cellContent) {
            emit(state.copyWith(content: cellContent ?? ""));
          },
          updateCell: (text) async {
            cellContext.saveCellData(text, resultCallback: (result) {
              result.fold(() => null, (err) => Log.error(err));
            });
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellContext.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    cellContext.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellContext.startListening(
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
  const factory NumberCellEvent.didReceiveCellUpdate(String? cellContent) = _DidReceiveCellUpdate;
}

@freezed
class NumberCellState with _$NumberCellState {
  const factory NumberCellState({
    required String content,
  }) = _NumberCellState;

  factory NumberCellState.initial(GridCellContext context) {
    final cellContent = context.getCellData() ?? "";
    return NumberCellState(content: cellContent);
  }
}
