import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'field_controller.dart';
import 'field_listener.dart';

part 'field_editor_bloc.freezed.dart';

class FieldEditorBloc extends Bloc<FieldEditorEvent, FieldEditorState> {
  final String fieldId;
  final SingleFieldListener _fieldListener;
  final FieldController fieldController;

  FieldEditorBloc({
    required this.fieldId,
    required this.fieldController,
    required bool isGroupField,
  })  : _fieldListener = SingleFieldListener(fieldId: fieldId),
        super(
          FieldEditorState.initial(fieldId, fieldController, isGroupField),
        ) {
    on<FieldEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _fieldListener.start(
              onFieldChanged: (field) {
                if (!isClosed) {
                  add(FieldEditorEvent.didReceiveFieldChanged(field));
                }
              },
            );
          },
          updateName: (name) {
            fieldController.fieldService
                .updateField(fieldId: fieldId, name: name);
          },
          didReceiveFieldChanged: (FieldPB field) {
            emit(state.copyWith(field: field));
          },
          deleteField: () {
            fieldController.fieldService.deleteField(fieldId: fieldId);
          },
          switchToField: (FieldType fieldType) async {
            await fieldController.fieldService.switchToField(
              fieldId: fieldId,
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
  const factory FieldEditorEvent.initial() = _InitialField;
  const factory FieldEditorEvent.updateName(String name) = _UpdateName;
  const factory FieldEditorEvent.deleteField() = _DeleteField;
  const factory FieldEditorEvent.switchToField(FieldType fieldType) =
      _SwitchToField;
  const factory FieldEditorEvent.didReceiveFieldChanged(FieldPB field) =
      _DidReceiveFieldChanged;
}

@freezed
class FieldEditorState with _$FieldEditorState {
  const factory FieldEditorState({
    required FieldPB field,
    required String errorText,
    required bool isGroupField,
  }) = _FieldEditorState;

  factory FieldEditorState.initial(
    String fieldId,
    FieldController fieldController,
    bool isGroupField,
  ) {
    final field = fieldController.getField(fieldId);
    return FieldEditorState(
      field: field!,
      errorText: '',
      isGroupField: isGroupField,
    );
  }
}
