import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'field_service.dart';
import 'type_option/type_option_context.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'type_option/type_option_data_controller.dart';

part 'field_editor_bloc.freezed.dart';

class FieldEditorBloc extends Bloc<FieldEditorEvent, FieldEditorState> {
  final TypeOptionController dataController;

  FieldEditorBloc({
    required bool isGroupField,
    required FieldPB field,
    required FieldTypeOptionLoader loader,
  })  : dataController = TypeOptionController(
          field: field,
          loader: loader,
        ),
        super(
          FieldEditorState.initial(
            loader.viewId,
            loader.field.name,
            isGroupField,
          ),
        ) {
    on<FieldEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            dataController.addFieldListener((field) {
              if (!isClosed) {
                add(FieldEditorEvent.didReceiveFieldChanged(field));
              }
            });
            await dataController.reloadTypeOption();
            add(FieldEditorEvent.didReceiveFieldChanged(dataController.field));
          },
          updateName: (name) {
            if (state.name != name) {
              dataController.fieldName = name;
              emit(state.copyWith(name: name));
            }
          },
          didReceiveFieldChanged: (FieldPB field) {
            emit(
              state.copyWith(
                field: Some(field),
                name: field.name,
                canDelete: field.isPrimary,
              ),
            );
          },
          deleteField: () {
            state.field.fold(
              () => null,
              (field) {
                final fieldService = FieldBackendService(
                  viewId: loader.viewId,
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
    required String viewId,
    required String errorText,
    required String name,
    required Option<FieldPB> field,
    required bool canDelete,
    required bool isGroupField,
  }) = _FieldEditorState;

  factory FieldEditorState.initial(
    String viewId,
    String fieldName,
    bool isGroupField,
  ) =>
      FieldEditorState(
        viewId: viewId,
        errorText: '',
        field: none(),
        canDelete: false,
        name: fieldName,
        isGroupField: isGroupField,
      );
}
