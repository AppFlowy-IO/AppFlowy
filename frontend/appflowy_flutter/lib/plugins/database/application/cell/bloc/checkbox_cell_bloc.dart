import 'dart:async';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkbox_cell_bloc.freezed.dart';

class CheckboxCellBloc extends Bloc<CheckboxCellEvent, CheckboxCellState> {
  CheckboxCellBloc({
    required this.cellController,
  }) : super(CheckboxCellState.initial(cellController)) {
    _dispatch();
  }

  final CheckboxCellController cellController;
  void Function()? _onCellChangedFn;

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
    on<CheckboxCellEvent>(
      (event, emit) {
        event.when(
          initial: () => _startListening(),
          didUpdateCell: (isSelected) {
            emit(state.copyWith(isSelected: isSelected));
          },
          didUpdateField: (fieldName) {
            emit(state.copyWith(fieldName: fieldName));
          },
          select: () {
            cellController.saveCellData(state.isSelected ? "No" : "Yes");
          },
        );
      },
    );
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (cellData) {
        if (!isClosed) {
          add(CheckboxCellEvent.didUpdateCell(_isSelected(cellData)));
        }
      },
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(CheckboxCellEvent.didUpdateField(fieldInfo.name));
    }
  }
}

@freezed
class CheckboxCellEvent with _$CheckboxCellEvent {
  const factory CheckboxCellEvent.initial() = _Initial;
  const factory CheckboxCellEvent.select() = _Selected;
  const factory CheckboxCellEvent.didUpdateCell(bool isSelected) =
      _DidUpdateCell;
  const factory CheckboxCellEvent.didUpdateField(String fieldName) =
      _DidUpdateField;
}

@freezed
class CheckboxCellState with _$CheckboxCellState {
  const factory CheckboxCellState({
    required bool isSelected,
    required String fieldName,
  }) = _CheckboxCellState;

  factory CheckboxCellState.initial(CheckboxCellController cellController) {
    return CheckboxCellState(
      isSelected: _isSelected(cellController.getCellData()),
      fieldName: cellController.fieldInfo.field.name,
    );
  }
}

bool _isSelected(CheckboxCellDataPB? cellData) {
  return cellData != null && cellData.isChecked;
}
