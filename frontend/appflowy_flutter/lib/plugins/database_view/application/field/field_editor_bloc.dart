import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'field_listener.dart';
import 'field_service.dart';

part 'field_editor_bloc.freezed.dart';

class FieldEditorBloc extends Bloc<FieldEditorEvent, FieldEditorState> {
  final String viewId;
  late final SingleFieldListener _fieldListener;

  FieldEditorBloc({
    required this.viewId,
    required bool isGroupField,
  }) : super(FieldEditorState.initial(isGroupField)) {
    on<FieldEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: (field) async {
            _fieldListener = SingleFieldListener(fieldId: field.id);
            _fieldListener.start(
              onFieldChanged: (field) {
                if (!isClosed) {
                  add(FieldEditorEvent.didReceiveFieldChanged(field));
                }
              },
            );
            emit(state.copyWith(field: field));
          },
          updateName: (name) {
            FieldBackendService.updateField(
              viewId: viewId,
              fieldId: state.field!.id,
              name: name,
            );
          },
          updateTypeOption: (typeOptionData) {
            FieldBackendService.updateFieldTypeOption(
              viewId: viewId,
              fieldId: state.field!.id,
              typeOptionData: typeOptionData,
            );
          },
          didReceiveFieldChanged: (FieldPB field) {
            emit(state.copyWith(field: field));
          },
          deleteField: () {
            FieldBackendService.deleteField(
              viewId: viewId,
              fieldId: state.field!.id,
            );
          },
          switchToField: (FieldType fieldType) async {
            await FieldBackendService.switchToField(
              viewId: viewId,
              fieldId: state.field!.id,
              newFieldType: fieldType,
            );
          },
        );
      },
    );
  }
}

@freezed
class FieldEditorEvent with _$FieldEditorEvent {
  const factory FieldEditorEvent.initial(FieldPB field) = _InitialField;
  const factory FieldEditorEvent.updateName(String name) = _UpdateName;
  const factory FieldEditorEvent.updateTypeOption(List<int> typeOptionData) =
      _UpdateTypeOption;
  const factory FieldEditorEvent.deleteField() = _DeleteField;
  const factory FieldEditorEvent.switchToField(FieldType fieldType) =
      _SwitchToField;
  const factory FieldEditorEvent.didReceiveFieldChanged(FieldPB field) =
      _DidReceiveFieldChanged;
}

@freezed
class FieldEditorState with _$FieldEditorState {
  const factory FieldEditorState({
    required FieldPB? field,
    required String errorText,
    required bool isGroupField,
  }) = _FieldEditorState;

  factory FieldEditorState.initial(bool isGroupField) {
    return FieldEditorState(
      field: null,
      errorText: '',
      isGroupField: isGroupField,
    );
  }
}
