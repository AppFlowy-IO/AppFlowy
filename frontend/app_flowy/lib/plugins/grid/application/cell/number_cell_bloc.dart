import 'package:appflowy_backend/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service/cell_service.dart';

part 'number_cell_bloc.freezed.dart';

class NumberCellBloc extends Bloc<NumberCellEvent, NumberCellState> {
  final GridNumberCellController cellController;
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
          updateCell: (text) {
            if (state.cellContent != text) {
              emit(state.copyWith(cellContent: text));
              cellController.saveCellData(text, onFinish: (result) {
                result.fold(
                  () {},
                  (err) => Log.error(err),
                );
              });
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
    _onCellChangedFn =
        cellController.startListening(onCellChanged: ((cellContent) {
      if (!isClosed) {
        add(NumberCellEvent.didReceiveCellUpdate(cellContent));
      }
    }), listenWhenOnCellChanged: (oldValue, newValue) {
      // If the new value is not the same as the content, which means the
      // backend formatted the content that user enter. For example:
      //
      // state.cellContent: "abc"
      // oldValue: ""
      // newValue: ""
      // The oldValue is the same as newValue. So the [onCellChanged] won't
      // get called. So just return true to refresh the cell content
      return true;
    });
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

  factory NumberCellState.initial(GridTextCellController context) {
    return NumberCellState(
      cellContent: context.getCellData() ?? "",
    );
  }
}
