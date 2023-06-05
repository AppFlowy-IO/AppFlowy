import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
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
    required final FieldCellContext cellContext,
  })  : _fieldListener = SingleFieldListener(fieldId: cellContext.field.id),
        _fieldBackendSvc = FieldBackendService(
          viewId: cellContext.viewId,
          fieldId: cellContext.field.id,
        ),
        super(FieldCellState.initial(cellContext)) {
    on<FieldCellEvent>(
      (final event, final emit) async {
        event.when(
          initial: () {
            _startListening();
          },
          didReceiveFieldUpdate: (final field) {
            emit(state.copyWith(field: cellContext.field));
          },
          startUpdateWidth: (final offset) {
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
      onFieldChanged: (final result) {
        if (isClosed) {
          return;
        }
        result.fold(
          (final field) => add(FieldCellEvent.didReceiveFieldUpdate(field)),
          (final err) => Log.error(err),
        );
      },
    );
  }
}

@freezed
class FieldCellEvent with _$FieldCellEvent {
  const factory FieldCellEvent.initial() = _InitialCell;
  const factory FieldCellEvent.didReceiveFieldUpdate(final FieldPB field) =
      _DidReceiveFieldUpdate;
  const factory FieldCellEvent.startUpdateWidth(final double offset) =
      _StartUpdateWidth;
  const factory FieldCellEvent.endUpdateWidth() = _EndUpdateWidth;
}

@freezed
class FieldCellState with _$FieldCellState {
  const factory FieldCellState({
    required final String viewId,
    required final FieldPB field,
    required final double width,
  }) = _FieldCellState;

  factory FieldCellState.initial(final FieldCellContext cellContext) =>
      FieldCellState(
        viewId: cellContext.viewId,
        field: cellContext.field,
        width: cellContext.field.width.toDouble(),
      );
}
