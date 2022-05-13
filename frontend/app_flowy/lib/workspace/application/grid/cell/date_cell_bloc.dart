import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Field;
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service/cell_service.dart';
import 'package:dartz/dartz.dart';
part 'date_cell_bloc.freezed.dart';

class DateCellBloc extends Bloc<DateCellEvent, DateCellState> {
  final GridDateCellContext cellContext;
  void Function()? _onCellChangedFn;

  DateCellBloc({required this.cellContext}) : super(DateCellState.initial(cellContext)) {
    on<DateCellEvent>(
      (event, emit) async {
        event.when(
          initial: () => _startListening(),
          didReceiveCellUpdate: (DateCellData value) => emit(state.copyWith(data: Some(value))),
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
  const factory DateCellEvent.didReceiveCellUpdate(DateCellData data) = _DidReceiveCellUpdate;
  const factory DateCellEvent.didReceiveFieldUpdate(Field field) = _DidReceiveFieldUpdate;
}

@freezed
class DateCellState with _$DateCellState {
  const factory DateCellState({
    required Option<DateCellData> data,
    required Field field,
  }) = _DateCellState;

  factory DateCellState.initial(GridDateCellContext context) {
    final cellData = context.getCellData();
    Option<DateCellData> data = none();

    if (cellData != null) {
      data = Some(cellData);
    }

    return DateCellState(
      field: context.field,
      data: data,
    );
  }
}
