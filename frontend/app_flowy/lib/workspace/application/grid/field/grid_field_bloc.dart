import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field_service.dart';

part 'grid_field_bloc.freezed.dart';

class GridFieldBloc extends Bloc<GridFieldEvent, GridFieldState> {
  final FieldService service;

  GridFieldBloc({required Field field, required this.service})
      : super(GridFieldState.initial(EditFieldContext.create()..gridField = field)) {
    on<GridFieldEvent>(
      (event, emit) async {
        await event.map(
          updateFieldName: (_UpdateFieldName value) async {
            final result = await service.updateField(fieldId: field.id, name: value.name);
            result.fold(
              (l) => null,
              (err) => Log.error(err),
            );
          },
          hideField: (_HideField value) async {
            final result = await service.updateField(fieldId: field.id, visibility: false);
            result.fold(
              (l) => null,
              (err) => Log.error(err),
            );
          },
          deleteField: (_DeleteField value) async {
            final result = await service.deleteField(fieldId: field.id);
            result.fold(
              (l) => null,
              (err) => Log.error(err),
            );
          },
          duplicateField: (_DuplicateField value) async {
            final result = await service.duplicateField(fieldId: field.id);
            result.fold(
              (l) => null,
              (err) => Log.error(err),
            );
          },
          saveField: (_SaveField value) {},
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
class GridFieldEvent with _$GridFieldEvent {
  const factory GridFieldEvent.updateFieldName(String name) = _UpdateFieldName;
  const factory GridFieldEvent.hideField() = _HideField;
  const factory GridFieldEvent.duplicateField() = _DuplicateField;
  const factory GridFieldEvent.deleteField() = _DeleteField;
  const factory GridFieldEvent.saveField() = _SaveField;
}

@freezed
class GridFieldState with _$GridFieldState {
  const factory GridFieldState({
    required EditFieldContext editContext,
    required String errorText,
    required String fieldName,
  }) = _GridFieldState;

  factory GridFieldState.initial(EditFieldContext editContext) => GridFieldState(
        editContext: editContext,
        errorText: '',
        fieldName: editContext.gridField.name,
      );
}
