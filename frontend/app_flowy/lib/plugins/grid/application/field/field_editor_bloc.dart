import 'package:appflowy_backend/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'field_service.dart';
import 'type_option/type_option_context.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'type_option/type_option_data_controller.dart';

part 'field_editor_bloc.freezed.dart';

class FieldEditorBloc extends Bloc<FieldEditorEvent, FieldEditorState> {
  final TypeOptionDataController dataController;

  FieldEditorBloc({
    required String gridId,
    required String fieldName,
    required bool isGroupField,
    required IFieldTypeOptionLoader loader,
  })  : dataController =
            TypeOptionDataController(gridId: gridId, loader: loader),
        super(FieldEditorState.initial(gridId, fieldName, isGroupField)) {
    on<FieldEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            dataController.addFieldListener((field) {
              if (!isClosed) {
                add(FieldEditorEvent.didReceiveFieldChanged(field));
              }
            });
            await dataController.loadTypeOptionData();
          },
          updateName: (name) {
            if (state.name != name) {
              dataController.fieldName = name;
              emit(state.copyWith(name: name));
            }
          },
          didReceiveFieldChanged: (FieldPB field) {
            emit(state.copyWith(
              field: Some(field),
              name: field.name,
              canDelete: field.isPrimary,
            ));
          },
          deleteField: () {
            state.field.fold(
              () => null,
              (field) {
                final fieldService = FieldService(
                  gridId: gridId,
                  fieldId: field.id,
                );
                fieldService.deleteField();
              },
            );
          },
          switchToField: (FieldType fieldType) async {
            await dataController.switchToField(fieldType);
          },
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
    required String gridId,
    required String errorText,
    required String name,
    required Option<FieldPB> field,
    required bool canDelete,
    required bool isGroupField,
  }) = _FieldEditorState;

  factory FieldEditorState.initial(
    String gridId,
    String fieldName,
    bool isGroupField,
  ) =>
      FieldEditorState(
        gridId: gridId,
        errorText: '',
        field: none(),
        canDelete: false,
        name: fieldName,
        isGroupField: isGroupField,
      );
}
