import 'dart:math';

import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import 'field_listener.dart';
import 'field_service.dart';

part 'field_cell_bloc.freezed.dart';

class FieldCellBloc extends Bloc<FieldCellEvent, FieldCellState> {
  final String viewId;
  final SingleFieldListener _fieldListener;
  final FieldBackendService _fieldBackendSvc;

  FieldCellBloc({
    required this.viewId,
    required FieldPB field,
  })  : _fieldListener = SingleFieldListener(fieldId: field.id),
        _fieldBackendSvc = FieldBackendService(viewId: viewId),
        super(FieldCellState.initial(field)) {
    on<FieldCellEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveFieldUpdate: (field) {
            emit(state.copyWith(field: field, width: field.width.toDouble()));
          },
          onResizeStart: () {
            emit(state.copyWith(resizeStart: state.width));
          },
          startUpdateWidth: (offset) {
            final width = max(offset + state.resizeStart, 50).toDouble();
            emit(state.copyWith(width: width));
          },
          endUpdateWidth: () {
            if (state.width != state.field.width.toDouble()) {
              _fieldBackendSvc.updateField(
                fieldId: field.id,
                width: state.width,
              );
            }
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _fieldListener.stop();
    return super.close();
  }

  void _startListening() {
    _fieldListener.start(
      onFieldChanged: (updatedField) {
        if (isClosed) {
          return;
        }
        add(FieldCellEvent.didReceiveFieldUpdate(updatedField));
      },
    );
  }
}

@freezed
class FieldCellEvent with _$FieldCellEvent {
  const factory FieldCellEvent.initial() = _InitialCell;
  const factory FieldCellEvent.didReceiveFieldUpdate(FieldPB field) =
      _DidReceiveFieldUpdate;
  const factory FieldCellEvent.onResizeStart() = _OnResizeStart;
  const factory FieldCellEvent.startUpdateWidth(double offset) =
      _StartUpdateWidth;
  const factory FieldCellEvent.endUpdateWidth() = _EndUpdateWidth;
}

@freezed
class FieldCellState with _$FieldCellState {
  const factory FieldCellState({
    required FieldPB field,
    required double width,
    required double resizeStart,
  }) = _FieldCellState;

  factory FieldCellState.initial(FieldPB field) => FieldCellState(
        field: field,
        width: field.width.toDouble(),
        resizeStart: 0,
      );
}
