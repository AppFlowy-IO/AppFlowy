import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Cell, Field;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service/cell_service.dart';
part 'date_cell_bloc.freezed.dart';

class DateCellBloc extends Bloc<DateCellEvent, DateCellState> {
  final GridDateCellContext cellContext;
  void Function()? _onCellChangedFn;

  DateCellBloc({required this.cellContext}) : super(DateCellState.initial(cellContext)) {
    on<DateCellEvent>(
      (event, emit) async {
        event.when(
          initial: () => _startListening(),
          selectDate: (DateCellPersistenceData value) => cellContext.saveCellData(value),
          didReceiveCellUpdate: (Cell value) => emit(state.copyWith(content: value.content)),
          didReceiveFieldUpdate: (Field value) => emit(state.copyWith(field: value)),
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
      onCellChanged: ((cell) {
        if (!isClosed) {
          add(DateCellEvent.didReceiveCellUpdate(cell));
        }
      }),
    );
  }
}

@freezed
class DateCellEvent with _$DateCellEvent {
  const factory DateCellEvent.initial() = _InitialCell;
  const factory DateCellEvent.selectDate(DateCellPersistenceData data) = _SelectDay;
  const factory DateCellEvent.didReceiveCellUpdate(Cell cell) = _DidReceiveCellUpdate;
  const factory DateCellEvent.didReceiveFieldUpdate(Field field) = _DidReceiveFieldUpdate;
}

@freezed
class DateCellState with _$DateCellState {
  const factory DateCellState({
    required String content,
    required Field field,
  }) = _DateCellState;

  factory DateCellState.initial(GridDateCellContext context) => DateCellState(
        field: context.field,
        content: context.getCellData()?.content ?? "",
      );
}
