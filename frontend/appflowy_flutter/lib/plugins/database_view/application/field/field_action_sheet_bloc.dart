import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'field_service.dart';

part 'field_action_sheet_bloc.freezed.dart';

class FieldActionSheetBloc
    extends Bloc<FieldActionSheetEvent, FieldActionSheetState> {
  final FieldBackendService fieldService;

  FieldActionSheetBloc({required FieldContext fieldCellContext})
      : fieldService = FieldBackendService(
          viewId: fieldCellContext.viewId,
          fieldId: fieldCellContext.field.id,
        ),
        super(
          FieldActionSheetState.initial(
            TypeOptionPB.create()..field_2 = fieldCellContext.field,
          ),
        ) {
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
          showField: (_ShowField value) async {
            final result = await fieldService.updateField(visibility: true);
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
}

@freezed
class FieldActionSheetEvent with _$FieldActionSheetEvent {
  const factory FieldActionSheetEvent.updateFieldName(String name) =
      _UpdateFieldName;
  const factory FieldActionSheetEvent.hideField() = _HideField;
  const factory FieldActionSheetEvent.showField() = _ShowField;
  const factory FieldActionSheetEvent.duplicateField() = _DuplicateField;
  const factory FieldActionSheetEvent.deleteField() = _DeleteField;
  const factory FieldActionSheetEvent.saveField() = _SaveField;
}

@freezed
class FieldActionSheetState with _$FieldActionSheetState {
  const factory FieldActionSheetState({
    required TypeOptionPB fieldTypeOptionData,
    required String errorText,
    required String fieldName,
  }) = _FieldActionSheetState;

  factory FieldActionSheetState.initial(TypeOptionPB data) =>
      FieldActionSheetState(
        fieldTypeOptionData: data,
        errorText: '',
        fieldName: data.field_2.name,
      );
}
