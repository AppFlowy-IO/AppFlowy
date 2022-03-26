import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'checkbox_cell_bloc.freezed.dart';

class CheckboxCellBloc extends Bloc<CheckboxCellEvent, CheckboxCellState> {
  final CellService service;
  // final FutureCellData cellData;

  CheckboxCellBloc({
    required this.service,
    required FutureCellData cellData,
  }) : super(CheckboxCellState.initial()) {
    cellData.then((a) {});

    on<CheckboxCellEvent>(
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
class CheckboxCellEvent with _$CheckboxCellEvent {
  const factory CheckboxCellEvent.initial() = _InitialCell;
}

@freezed
class CheckboxCellState with _$CheckboxCellState {
  const factory CheckboxCellState({
    required Cell? cell,
  }) = _CheckboxCellState;

  factory CheckboxCellState.initial() => const CheckboxCellState(cell: null);
}
