import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';

part 'property_bloc.freezed.dart';

class GridPropertyBloc extends Bloc<GridPropertyEvent, GridPropertyState> {
  final FieldService _service;
  GridPropertyBloc({required String gridId, required List<Field> fields})
      : _service = FieldService(gridId: gridId),
        super(GridPropertyState.initial(gridId, fields)) {
    on<GridPropertyEvent>(
      (event, emit) async {
        await event.map(setFieldVisibility: (_SetFieldVisibility value) async {
          final result = await _service.updateField(fieldId: value.fieldId, visibility: value.visibility);
          result.fold(
            (l) => null,
            (err) => Log.error(err),
          );
        });
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
class GridPropertyEvent with _$GridPropertyEvent {
  const factory GridPropertyEvent.setFieldVisibility(String fieldId, bool visibility) = _SetFieldVisibility;
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
