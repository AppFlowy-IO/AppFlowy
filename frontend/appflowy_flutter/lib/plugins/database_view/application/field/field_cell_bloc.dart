import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import 'field_listener.dart';
import 'field_service.dart';

part 'field_cell_bloc.freezed.dart';

class FieldCellBloc extends Bloc<FieldCellEvent, FieldCellState> {
  final SingleFieldListener _fieldListener;
  final FieldBackendService _fieldBackendSvc;

  FieldCellBloc({
    required FieldContext cellContext,
  })  : _fieldListener = SingleFieldListener(fieldId: cellContext.field.id),
        _fieldBackendSvc = FieldBackendService(
          viewId: cellContext.viewId,
          fieldId: cellContext.field.id,
        ),
        super(FieldCellState.initial(cellContext)) {
    on<FieldCellEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveFieldUpdate: (field) {
            emit(state.copyWith(field: cellContext.field));
          },
          startUpdateWidth: (offset) {
            final width = state.width + offset;
            emit(state.copyWith(width: width));
          },
          endUpdateWidth: () {
            if (state.width != state.field.width.toDouble()) {
              _fieldBackendSvc.updateField(width: state.width);
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
      onFieldChanged: (result) {
        if (isClosed) {
          return;
        }
        result.fold(
          (field) => add(FieldCellEvent.didReceiveFieldUpdate(field)),
          (err) => Log.error(err),
        );
      },
    );
  }
}

@freezed
class FieldCellEvent with _$FieldCellEvent {
  const factory FieldCellEvent.initial() = _InitialCell;
  const factory FieldCellEvent.didReceiveFieldUpdate(FieldPB field) =
      _DidReceiveFieldUpdate;
  const factory FieldCellEvent.startUpdateWidth(double offset) =
      _StartUpdateWidth;
  const factory FieldCellEvent.endUpdateWidth() = _EndUpdateWidth;
}

@freezed
class FieldCellState with _$FieldCellState {
  const factory FieldCellState({
    required String viewId,
    required FieldPB field,
    required double width,
  }) = _FieldCellState;

  factory FieldCellState.initial(FieldContext cellContext) => FieldCellState(
        viewId: cellContext.viewId,
        field: cellContext.field,
        width: cellContext.field.width.toDouble(),
      );
}
