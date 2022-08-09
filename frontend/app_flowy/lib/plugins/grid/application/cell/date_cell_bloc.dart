import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service/cell_service.dart';
part 'date_cell_bloc.freezed.dart';

class DateCellBloc extends Bloc<DateCellEvent, DateCellState> {
  final GridDateCellController cellContext;
  void Function()? _onCellChangedFn;

  DateCellBloc({required this.cellContext}) : super(DateCellState.initial(cellContext)) {
    on<DateCellEvent>(
      (event, emit) async {
        event.when(
          initial: () => _startListening(),
          didReceiveCellUpdate: (DateCellDataPB? cellData) {
            emit(state.copyWith(data: cellData, dateStr: _dateStrFromCellData(cellData)));
          },
          didReceiveFieldUpdate: (GridFieldPB value) => emit(state.copyWith(field: value)),
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
      onCellChanged: ((data) {
        if (!isClosed) {
          add(DateCellEvent.didReceiveCellUpdate(data));
        }
      }),
    );
  }
}

@freezed
class DateCellEvent with _$DateCellEvent {
  const factory DateCellEvent.initial() = _InitialCell;
  const factory DateCellEvent.didReceiveCellUpdate(DateCellDataPB? data) = _DidReceiveCellUpdate;
  const factory DateCellEvent.didReceiveFieldUpdate(GridFieldPB field) = _DidReceiveFieldUpdate;
}

@freezed
class DateCellState with _$DateCellState {
  const factory DateCellState({
    required DateCellDataPB? data,
    required String dateStr,
    required GridFieldPB field,
  }) = _DateCellState;

  factory DateCellState.initial(GridDateCellController context) {
    final cellData = context.getCellData();

    return DateCellState(
      field: context.field,
      data: cellData,
      dateStr: _dateStrFromCellData(cellData),
    );
  }
}

String _dateStrFromCellData(DateCellDataPB? cellData) {
  String dateStr = "";
  if (cellData != null) {
    dateStr = cellData.date + " " + cellData.time;
  }
  return dateStr;
}
