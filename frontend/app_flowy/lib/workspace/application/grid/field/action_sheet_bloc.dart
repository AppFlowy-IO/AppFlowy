import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field_service.dart';

part 'action_sheet_bloc.freezed.dart';

class FieldActionSheetBloc extends Bloc<ActionSheetEvent, ActionSheetState> {
  final FieldService service;

  FieldActionSheetBloc({required Field field, required this.service})
      : super(ActionSheetState.initial(EditFieldContext.create()..gridField = field)) {
    on<ActionSheetEvent>(
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
class ActionSheetEvent with _$ActionSheetEvent {
  const factory ActionSheetEvent.updateFieldName(String name) = _UpdateFieldName;
  const factory ActionSheetEvent.hideField() = _HideField;
  const factory ActionSheetEvent.duplicateField() = _DuplicateField;
  const factory ActionSheetEvent.deleteField() = _DeleteField;
  const factory ActionSheetEvent.saveField() = _SaveField;
}

@freezed
class ActionSheetState with _$ActionSheetState {
  const factory ActionSheetState({
    required EditFieldContext editContext,
    required String errorText,
    required String fieldName,
  }) = _ActionSheetState;

  factory ActionSheetState.initial(EditFieldContext editContext) => ActionSheetState(
        editContext: editContext,
        errorText: '',
        fieldName: editContext.gridField.name,
      );
}
