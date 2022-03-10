import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'number_cell_bloc.freezed.dart';

class NumberCellBloc extends Bloc<NumberCellEvent, NumberCellState> {
  final Field field;
  final Cell? cell;
  final CellService service;

  NumberCellBloc({
    required this.field,
    required this.cell,
    required this.service,
  }) : super(NumberCellState.initial(cell)) {
    on<NumberCellEvent>(
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
abstract class NumberCellEvent with _$NumberCellEvent {
  const factory NumberCellEvent.initial() = _InitialCell;
}

@freezed
abstract class NumberCellState with _$NumberCellState {
  const factory NumberCellState({
    required Cell? cell,
  }) = _NumberCellState;

  factory NumberCellState.initial(Cell? cell) => NumberCellState(cell: cell);
}
