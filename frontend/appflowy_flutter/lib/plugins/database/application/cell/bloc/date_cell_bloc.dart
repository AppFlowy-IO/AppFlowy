import 'dart:async';
import 'dart:ui';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'date_cell_editor_bloc.dart';

part 'date_cell_bloc.freezed.dart';

class DateCellBloc extends Bloc<DateCellEvent, DateCellState> {
  DateCellBloc({required this.cellController})
      : super(DateCellState.initial(cellController)) {
    _dispatch();
    _startListening();
  }

  final DateCellController cellController;
  VoidCallback? _onCellChangedFn;

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(
        onCellChanged: _onCellChangedFn!,
        onFieldChanged: _onFieldChangedListener,
      );
    }
    await cellController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<DateCellEvent>(
      (event, emit) async {
        event.when(
          didReceiveCellUpdate: (DateCellDataPB? cellData) {
            final dateCellData = DateCellData.fromPB(cellData);
            emit(
              state.copyWith(
                cellData: dateCellData,
              ),
            );
          },
          didUpdateField: (fieldInfo) {
            emit(
              state.copyWith(
                fieldInfo: fieldInfo,
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (data) {
        if (!isClosed) {
          add(DateCellEvent.didReceiveCellUpdate(data));
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(DateCellEvent.didUpdateField(fieldInfo));
    }
  }
}

@freezed
class DateCellEvent with _$DateCellEvent {
  const factory DateCellEvent.didReceiveCellUpdate(DateCellDataPB? data) =
      _DidReceiveCellUpdate;
  const factory DateCellEvent.didUpdateField(FieldInfo fieldInfo) =
      _DidUpdateField;
}

@freezed
class DateCellState with _$DateCellState {
  const factory DateCellState({
    required FieldInfo fieldInfo,
    required DateCellData cellData,
  }) = _DateCellState;

  factory DateCellState.initial(DateCellController cellController) {
    final cellData = DateCellData.fromPB(cellController.getCellData());

    return DateCellState(
      fieldInfo: cellController.fieldInfo,
      cellData: cellData,
    );
  }
}
