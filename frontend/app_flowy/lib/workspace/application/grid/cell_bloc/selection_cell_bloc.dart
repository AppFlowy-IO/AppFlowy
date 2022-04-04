import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'selection_cell_bloc.freezed.dart';

class SelectionCellBloc extends Bloc<SelectionCellEvent, SelectionCellState> {
  final CellService service;

  SelectionCellBloc({
    required this.service,
    required FutureCellData cellData,
  }) : super(SelectionCellState.initial()) {
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
class SelectionCellEvent with _$SelectionCellEvent {
  const factory SelectionCellEvent.initial() = _InitialCell;
}

@freezed
class SelectionCellState with _$SelectionCellState {
  const factory SelectionCellState() = _SelectionCellState;
  // required String girdId,
  //   required Field field,
  //   required List<SelectOption> options,

  factory SelectionCellState.initial() => const SelectionCellState();
}
