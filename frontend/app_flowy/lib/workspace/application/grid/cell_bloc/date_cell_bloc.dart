import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'date_cell_bloc.freezed.dart';

class DateCellBloc extends Bloc<DateCellEvent, DateCellState> {
  final Field field;
  final Cell? cell;
  final CellService service;

  DateCellBloc({
    required this.field,
    required this.cell,
    required this.service,
  }) : super(DateCellState.initial(cell)) {
    on<DateCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialCell value) async {},
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
abstract class DateCellEvent with _$DateCellEvent {
  const factory DateCellEvent.initial() = _InitialCell;
}

@freezed
abstract class DateCellState with _$DateCellState {
  const factory DateCellState({
    required Cell? cell,
  }) = _DateCellState;

  factory DateCellState.initial(Cell? cell) => DateCellState(cell: cell);
}
