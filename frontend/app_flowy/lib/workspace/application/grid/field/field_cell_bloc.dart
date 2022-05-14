import 'package:app_flowy/workspace/application/grid/field/field_listener.dart';
import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Field;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'field_cell_bloc.freezed.dart';

class FieldCellBloc extends Bloc<FieldCellEvent, FieldCellState> {
  final SingleFieldListener _fieldListener;
  final FieldService _fieldService;

  FieldCellBloc({
    required GridFieldCellContext cellContext,
  })  : _fieldListener = SingleFieldListener(fieldId: cellContext.field.id),
        _fieldService = FieldService(gridId: cellContext.gridId, fieldId: cellContext.field.id),
        super(FieldCellState.initial(cellContext)) {
    on<FieldCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialCell value) async {
            _startListening();
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(field: value.field));
          },
          updateWidth: (_UpdateWidth value) {
            final defaultWidth = state.field.width.toDouble();
            final width = defaultWidth + value.offset;
            if (width > defaultWidth && width < 300) {
              _fieldService.updateField(width: width);
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
    _fieldListener.start(onFieldChanged: (result) {
      if (isClosed) {
        return;
      }
      result.fold(
        (field) => add(FieldCellEvent.didReceiveFieldUpdate(field)),
        (err) => Log.error(err),
      );
    });
  }
}

@freezed
class FieldCellEvent with _$FieldCellEvent {
  const factory FieldCellEvent.initial() = _InitialCell;
  const factory FieldCellEvent.didReceiveFieldUpdate(Field field) = _DidReceiveFieldUpdate;
  const factory FieldCellEvent.updateWidth(double offset) = _UpdateWidth;
}

@freezed
class FieldCellState with _$FieldCellState {
  const factory FieldCellState({
    required String gridId,
    required Field field,
  }) = _FieldCellState;

  factory FieldCellState.initial(GridFieldCellContext cellContext) => FieldCellState(
        gridId: cellContext.gridId,
        field: cellContext.field,
      );
}
