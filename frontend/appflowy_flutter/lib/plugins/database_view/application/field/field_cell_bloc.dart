import 'dart:math';

import 'package:appflowy/plugins/database_view/application/field_settings/field_settings_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'field_info.dart';

part 'field_cell_bloc.freezed.dart';

class FieldCellBloc extends Bloc<FieldCellEvent, FieldCellState> {
  FieldInfo fieldInfo;
  final FieldSettingsBackendService _fieldSettingsService;

  FieldCellBloc({required String viewId, required this.fieldInfo})
      : _fieldSettingsService = FieldSettingsBackendService(
          viewId: viewId,
        ),
        super(FieldCellState.initial(fieldInfo)) {
    on<FieldCellEvent>(
      (event, emit) async {
        event.when(
          onFieldChanged: (newFieldInfo) {
            fieldInfo = newFieldInfo;
            emit(FieldCellState.initial(newFieldInfo));
          },
          onResizeStart: () {
            emit(state.copyWith(isResizing: true, resizeStart: state.width));
          },
          startUpdateWidth: (offset) {
            final width = max(offset + state.resizeStart, 50).toDouble();
            emit(state.copyWith(width: width));
          },
          endUpdateWidth: () {
            if (state.width != fieldInfo.fieldSettings?.width.toDouble()) {
              _fieldSettingsService.updateFieldSettings(
                fieldId: fieldInfo.id,
                width: state.width,
              );
            }
            emit(state.copyWith(isResizing: false, resizeStart: 0));
          },
        );
      },
    );
  }
}

@freezed
class FieldCellEvent with _$FieldCellEvent {
  const factory FieldCellEvent.onFieldChanged(FieldInfo newFieldInfo) =
      _OnFieldChanged;
  const factory FieldCellEvent.onResizeStart() = _OnResizeStart;
  const factory FieldCellEvent.startUpdateWidth(double offset) =
      _StartUpdateWidth;
  const factory FieldCellEvent.endUpdateWidth() = _EndUpdateWidth;
}

@freezed
class FieldCellState with _$FieldCellState {
  const factory FieldCellState({
    required FieldInfo fieldInfo,
    required double width,
    required bool isResizing,
    required double resizeStart,
  }) = _FieldCellState;

  factory FieldCellState.initial(FieldInfo fieldInfo) => FieldCellState(
        fieldInfo: fieldInfo,
        isResizing: false,
        width: fieldInfo.fieldSettings!.width.toDouble(),
        resizeStart: 0,
      );
}
