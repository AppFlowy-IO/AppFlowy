import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../../../application/cell/cell_controller_builder.dart';
part 'date_card_cell_bloc.freezed.dart';

class DateCardCellBloc extends Bloc<DateCardCellEvent, DateCardCellState> {
  final DateCellController cellController;
  void Function()? _onCellChangedFn;

  DateCardCellBloc({required this.cellController})
      : super(DateCardCellState.initial(cellController)) {
    on<DateCardCellEvent>(
      (event, emit) async {
        event.when(
          initial: () => _startListening(),
          didReceiveCellUpdate: (DateCellDataPB? cellData) {
            emit(
              state.copyWith(
                data: cellData,
                dateStr: _dateStrFromCellData(cellData),
              ),
            );
          },
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
    await cellController.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellController.startListening(
      onCellChanged: ((data) {
        if (!isClosed) {
          add(DateCardCellEvent.didReceiveCellUpdate(data));
        }
      }),
    );
  }
}

@freezed
class DateCardCellEvent with _$DateCardCellEvent {
  const factory DateCardCellEvent.initial() = _InitialCell;
  const factory DateCardCellEvent.didReceiveCellUpdate(DateCellDataPB? data) =
      _DidReceiveCellUpdate;
}

@freezed
class DateCardCellState with _$DateCardCellState {
  const factory DateCardCellState({
    required DateCellDataPB? data,
    required String dateStr,
    required FieldInfo fieldInfo,
  }) = _DateCardCellState;

  factory DateCardCellState.initial(DateCellController context) {
    final cellData = context.getCellData();

    return DateCardCellState(
      fieldInfo: context.fieldInfo,
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
