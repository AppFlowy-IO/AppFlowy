import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'field_service.dart';

part 'field_action_sheet_bloc.freezed.dart';

class FieldActionSheetBloc
    extends Bloc<FieldActionSheetEvent, FieldActionSheetState> {
  final FieldBackendService fieldService;

  FieldActionSheetBloc({required final FieldCellContext fieldCellContext})
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
      (final event, final emit) async {
        await event.map(
          updateFieldName: (final _UpdateFieldName value) async {
            final result = await fieldService.updateField(name: value.name);
            result.fold(
              (final l) => null,
              (final err) => Log.error(err),
            );
          },
          hideField: (final _HideField value) async {
            final result = await fieldService.updateField(visibility: false);
            result.fold(
              (final l) => null,
              (final err) => Log.error(err),
            );
          },
          showField: (final _ShowField value) async {
            final result = await fieldService.updateField(visibility: true);
            result.fold(
              (final l) => null,
              (final err) => Log.error(err),
            );
          },
          deleteField: (final _DeleteField value) async {
            final result = await fieldService.deleteField();
            result.fold(
              (final l) => null,
              (final err) => Log.error(err),
            );
          },
          duplicateField: (final _DuplicateField value) async {
            final result = await fieldService.duplicateField();
            result.fold(
              (final l) => null,
              (final err) => Log.error(err),
            );
          },
          saveField: (final _SaveField value) {},
        );
      },
    );
  }
}

@freezed
class FieldActionSheetEvent with _$FieldActionSheetEvent {
  const factory FieldActionSheetEvent.updateFieldName(final String name) =
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
    required final TypeOptionPB fieldTypeOptionData,
    required final String errorText,
    required final String fieldName,
  }) = _FieldActionSheetState;

  factory FieldActionSheetState.initial(final TypeOptionPB data) =>
      FieldActionSheetState(
        fieldTypeOptionData: data,
        errorText: '',
        fieldName: data.field_2.name,
      );
}
