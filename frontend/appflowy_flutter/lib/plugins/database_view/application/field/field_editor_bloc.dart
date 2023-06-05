import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
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
    required final String viewId,
    required final String fieldName,
    required final bool isGroupField,
    required final IFieldTypeOptionLoader loader,
  })  : dataController = TypeOptionController(viewId: viewId, loader: loader),
        super(FieldEditorState.initial(viewId, fieldName, isGroupField)) {
    on<FieldEditorEvent>(
      (final event, final emit) async {
        await event.when(
          initial: () async {
            dataController.addFieldListener((final field) {
              if (!isClosed) {
                add(FieldEditorEvent.didReceiveFieldChanged(field));
              }
            });
            await dataController.loadTypeOptionData();
          },
          updateName: (final name) {
            if (state.name != name) {
              dataController.fieldName = name;
              emit(state.copyWith(name: name));
            }
          },
          didReceiveFieldChanged: (final FieldPB field) {
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
              (final field) {
                final fieldService = FieldBackendService(
                  viewId: viewId,
                  fieldId: field.id,
                );
                fieldService.deleteField();
              },
            );
          },
          switchToField: (final FieldType fieldType) async {
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
  const factory FieldEditorEvent.updateName(final String name) = _UpdateName;
  const factory FieldEditorEvent.deleteField() = _DeleteField;
  const factory FieldEditorEvent.switchToField(final FieldType fieldType) =
      _SwitchToField;
  const factory FieldEditorEvent.didReceiveFieldChanged(final FieldPB field) =
      _DidReceiveFieldChanged;
}

@freezed
class FieldEditorState with _$FieldEditorState {
  const factory FieldEditorState({
    required final String viewId,
    required final String errorText,
    required final String name,
    required final Option<FieldPB> field,
    required final bool canDelete,
    required final bool isGroupField,
  }) = _FieldEditorState;

  factory FieldEditorState.initial(
    final String viewId,
    final String fieldName,
    final bool isGroupField,
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
