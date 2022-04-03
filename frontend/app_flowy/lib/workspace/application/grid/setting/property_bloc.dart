import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:app_flowy/workspace/application/grid/field/grid_listenr.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'property_bloc.freezed.dart';

class GridPropertyBloc extends Bloc<GridPropertyEvent, GridPropertyState> {
  final FieldService _service;
  final GridFieldsListener _fieldListener;

  GridPropertyBloc({required String gridId, required List<Field> fields})
      : _service = FieldService(gridId: gridId),
        _fieldListener = GridFieldsListener(gridId: gridId),
        super(GridPropertyState.initial(gridId, fields)) {
    on<GridPropertyEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) {
            _startListening();
          },
          setFieldVisibility: (_SetFieldVisibility value) async {
            final result = await _service.updateField(fieldId: value.fieldId, visibility: value.visibility);
            result.fold(
              (l) => null,
              (err) => Log.error(err),
            );
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(fields: value.fields));
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
    _fieldListener.updateFieldsNotifier.addPublishListener((result) {
      result.fold(
        (fields) {
          add(GridPropertyEvent.didReceiveFieldUpdate(fields));
        },
        (err) => Log.error(err),
      );
    });
    _fieldListener.start();
  }
}

@freezed
class GridPropertyEvent with _$GridPropertyEvent {
  const factory GridPropertyEvent.initial() = _Initial;
  const factory GridPropertyEvent.setFieldVisibility(String fieldId, bool visibility) = _SetFieldVisibility;
  const factory GridPropertyEvent.didReceiveFieldUpdate(List<Field> fields) = _DidReceiveFieldUpdate;
}

@freezed
class GridPropertyState with _$GridPropertyState {
  const factory GridPropertyState({
    required String gridId,
    required List<Field> fields,
  }) = _GridPropertyState;

  factory GridPropertyState.initial(String gridId, List<Field> fields) => GridPropertyState(
        gridId: gridId,
        fields: fields,
      );
}
