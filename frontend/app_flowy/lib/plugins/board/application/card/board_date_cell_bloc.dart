import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
part 'board_date_cell_bloc.freezed.dart';

class BoardDateCellBloc extends Bloc<BoardDateCellEvent, BoardDateCellState> {
  final GridDateCellController cellController;
  void Function()? _onCellChangedFn;

  BoardDateCellBloc({required this.cellController})
      : super(BoardDateCellState.initial(cellController)) {
    on<BoardDateCellEvent>(
      (event, emit) async {
        event.when(
          initial: () => _startListening(),
          didReceiveCellUpdate: (DateCellDataPB? cellData) {
            emit(state.copyWith(
                data: cellData, dateStr: _dateStrFromCellData(cellData)));
          },
          didReceiveFieldUpdate: (FieldPB value) =>
              emit(state.copyWith(field: value)),
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
    cellController.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellController.startListening(
      onCellChanged: ((data) {
        if (!isClosed) {
          add(BoardDateCellEvent.didReceiveCellUpdate(data));
        }
      }),
    );
  }
}

@freezed
class BoardDateCellEvent with _$BoardDateCellEvent {
  const factory BoardDateCellEvent.initial() = _InitialCell;
  const factory BoardDateCellEvent.didReceiveCellUpdate(DateCellDataPB? data) =
      _DidReceiveCellUpdate;
  const factory BoardDateCellEvent.didReceiveFieldUpdate(FieldPB field) =
      _DidReceiveFieldUpdate;
}

@freezed
class BoardDateCellState with _$BoardDateCellState {
  const factory BoardDateCellState({
    required DateCellDataPB? data,
    required String dateStr,
    required FieldPB field,
  }) = _BoardDateCellState;

  factory BoardDateCellState.initial(GridDateCellController context) {
    final cellData = context.getCellData();

    return BoardDateCellState(
      field: context.field,
      data: cellData,
      dateStr: _dateStrFromCellData(cellData),
    );
  }
}

String _dateStrFromCellData(DateCellDataPB? cellData) {
  String dateStr = "";
  if (cellData != null) {
    dateStr = "${cellData.date} ${cellData.time}";
  }
  return dateStr;
}
