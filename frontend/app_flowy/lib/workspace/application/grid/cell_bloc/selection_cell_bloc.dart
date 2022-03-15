import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'selection_cell_bloc.freezed.dart';

class SelectionCellBloc extends Bloc<SelectionCellEvent, SelectionCellState> {
  final Field field;
  final Cell? cell;
  final CellService service;

  SelectionCellBloc({
    required this.field,
    required this.cell,
    required this.service,
  }) : super(SelectionCellState.initial(cell)) {
    on<SelectionCellEvent>(
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
abstract class SelectionCellEvent with _$SelectionCellEvent {
  const factory SelectionCellEvent.initial() = _InitialCell;
}

@freezed
abstract class SelectionCellState with _$SelectionCellState {
  const factory SelectionCellState({
    required Cell? cell,
  }) = _SelectionCellState;

  factory SelectionCellState.initial(Cell? cell) => SelectionCellState(cell: cell);
}
