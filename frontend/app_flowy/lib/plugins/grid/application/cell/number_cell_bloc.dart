import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'cell_service/cell_service.dart';

part 'number_cell_bloc.freezed.dart';

class NumberCellBloc extends Bloc<NumberCellEvent, NumberCellState> {
  final GridCellController cellController;
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
          didReceiveCellUpdate: (content) {
            emit(state.copyWith(content: content));
          },
          updateCell: (text) {
            cellController.saveCellData(text, resultCallback: (result) {
              result.fold(
                () => null,
                (err) {
                  if (!isClosed) {
                    add(NumberCellEvent.didReceiveCellUpdate(right(err)));
                  }
                },
              );
            });
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
          add(NumberCellEvent.didReceiveCellUpdate(left(cellContent ?? "")));
        }
      }),
    );
  }
}

@freezed
class NumberCellEvent with _$NumberCellEvent {
  const factory NumberCellEvent.initial() = _Initial;
  const factory NumberCellEvent.updateCell(String text) = _UpdateCell;
  const factory NumberCellEvent.didReceiveCellUpdate(
      Either<String, FlowyError> cellContent) = _DidReceiveCellUpdate;
}

@freezed
class NumberCellState with _$NumberCellState {
  const factory NumberCellState({
    required Either<String, FlowyError> content,
  }) = _NumberCellState;

  factory NumberCellState.initial(GridCellController context) {
    final cellContent = context.getCellData() ?? "";
    return NumberCellState(
      content: left(cellContent),
    );
  }
}
