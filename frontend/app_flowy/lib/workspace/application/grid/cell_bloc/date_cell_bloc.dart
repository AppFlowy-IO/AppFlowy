import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'date_cell_bloc.freezed.dart';

class DateCellBloc extends Bloc<DateCellEvent, DateCellState> {
  final CellService service;
  final FutureCellData cellData;

  DateCellBloc({
    required this.service,
    required this.cellData,
  }) : super(DateCellState.initial()) {
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
class DateCellEvent with _$DateCellEvent {
  const factory DateCellEvent.initial() = _InitialCell;
}

@freezed
class DateCellState with _$DateCellState {
  const factory DateCellState({
    Cell? cell,
  }) = _DateCellState;

  factory DateCellState.initial() => const DateCellState();
}
