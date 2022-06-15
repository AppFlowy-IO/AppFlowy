import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/field.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field_service.dart';

part 'field_action_sheet_bloc.freezed.dart';

class FieldActionSheetBloc extends Bloc<FieldActionSheetEvent, FieldActionSheetState> {
  final FieldService fieldService;

  FieldActionSheetBloc({required Field field, required this.fieldService})
      : super(FieldActionSheetState.initial(FieldTypeOptionData.create()..field_2 = field)) {
    on<FieldActionSheetEvent>(
      (event, emit) async {
        await event.map(
          updateFieldName: (_UpdateFieldName value) async {
            final result = await fieldService.updateField(name: value.name);
            result.fold(
              (l) => null,
              (err) => Log.error(err),
            );
          },
          hideField: (_HideField value) async {
            final result = await fieldService.updateField(visibility: false);
            result.fold(
              (l) => null,
              (err) => Log.error(err),
            );
          },
          deleteField: (_DeleteField value) async {
            final result = await fieldService.deleteField();
            result.fold(
              (l) => null,
              (err) => Log.error(err),
            );
          },
          duplicateField: (_DuplicateField value) async {
            final result = await fieldService.duplicateField();
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
class FieldActionSheetEvent with _$FieldActionSheetEvent {
  const factory FieldActionSheetEvent.updateFieldName(String name) = _UpdateFieldName;
  const factory FieldActionSheetEvent.hideField() = _HideField;
  const factory FieldActionSheetEvent.duplicateField() = _DuplicateField;
  const factory FieldActionSheetEvent.deleteField() = _DeleteField;
  const factory FieldActionSheetEvent.saveField() = _SaveField;
}

@freezed
class FieldActionSheetState with _$FieldActionSheetState {
  const factory FieldActionSheetState({
    required FieldTypeOptionData fieldTypeOptionData,
    required String errorText,
    required String fieldName,
  }) = _FieldActionSheetState;

  factory FieldActionSheetState.initial(FieldTypeOptionData data) => FieldActionSheetState(
        fieldTypeOptionData: data,
        errorText: '',
        fieldName: data.field_2.name,
      );
}
