import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database/date_type_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
part 'date_cell_bloc.freezed.dart';

class DateCellBloc extends Bloc<DateCellEvent, DateCellState> {
  final DateCellController cellController;
  void Function()? _onCellChangedFn;

  DateCellBloc({required this.cellController})
      : super(DateCellState.initial(cellController)) {
    on<DateCellEvent>(
      (final event, final emit) async {
        event.when(
          initial: () => _startListening(),
          didReceiveCellUpdate: (final DateCellDataPB? cellData) {
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
      onCellChanged: ((final data) {
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
  const factory DateCellEvent.didReceiveCellUpdate(final DateCellDataPB? data) =
      _DidReceiveCellUpdate;
}

@freezed
class DateCellState with _$DateCellState {
  const factory DateCellState({
    required final DateCellDataPB? data,
    required final String dateStr,
    required final FieldInfo fieldInfo,
  }) = _DateCellState;

  factory DateCellState.initial(final DateCellController context) {
    final cellData = context.getCellData();

    return DateCellState(
      fieldInfo: context.fieldInfo,
      data: cellData,
      dateStr: _dateStrFromCellData(cellData),
    );
  }
}

String _dateStrFromCellData(final DateCellDataPB? cellData) {
  String dateStr = "";
  if (cellData != null) {
    dateStr = "${cellData.date} ${cellData.time}";
  }
  return dateStr;
}
