import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_service.dart';
import 'package:appflowy/plugins/database_view/application/field_settings/field_settings_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'field_controller.dart';
import 'field_info.dart';
import 'field_listener.dart';
import 'field_service.dart';
import 'type_option/type_option_context.dart';
import 'type_option/type_option_data_controller.dart';

part 'field_editor_bloc.freezed.dart';

class FieldEditorBloc extends Bloc<FieldEditorEvent, FieldEditorState> {
  final FieldPB field;

  final String viewId;
  final FieldController fieldController;
  final SingleFieldListener _singleFieldListener;
  final FieldBackendService fieldService;
  final FieldSettingsBackendService fieldSettingsService;
  final TypeOptionController typeOptionController;
  final void Function(String newFieldId)? onFieldInserted;

  FieldEditorBloc({
    required this.viewId,
    required this.field,
    required this.fieldController,
    this.onFieldInserted,
    required FieldTypeOptionLoader loader,
  })  : typeOptionController = TypeOptionController(
          field: field,
          loader: loader,
        ),
        _singleFieldListener = SingleFieldListener(fieldId: field.id),
        fieldService = FieldBackendService(
          viewId: viewId,
          fieldId: field.id,
        ),
        fieldSettingsService = FieldSettingsBackendService(viewId: viewId),
        super(FieldEditorState(field: FieldInfo.initial(field))) {
    on<FieldEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final fieldId = field.id;
            typeOptionController.addFieldListener((field) {
              if (!isClosed) {
                add(FieldEditorEvent.didReceiveFieldChanged(fieldId));
              }
            });
            _singleFieldListener.start(
              onFieldChanged: (field) {
                if (!isClosed) {
                  add(FieldEditorEvent.didReceiveFieldChanged(fieldId));
                }
              },
            );
            await typeOptionController.reloadTypeOption();
            add(FieldEditorEvent.didReceiveFieldChanged(fieldId));
          },
          didReceiveFieldChanged: (fieldId) async {
            await Future.delayed(const Duration(milliseconds: 50));
            emit(state.copyWith(field: fieldController.getField(fieldId)!));
          },
          switchFieldType: (fieldType) async {
            await typeOptionController.switchToField(fieldType);
          },
          renameField: (newName) async {
            final result = await fieldService.updateField(name: newName);
            _logIfError(result);
          },
          insertLeft: () async {
            final result = await TypeOptionBackendService.createFieldTypeOption(
              viewId: viewId,
              position: CreateFieldPosition.Before,
              targetFieldId: field.id,
            );
            result.fold(
              (typeOptionPB) => onFieldInserted?.call(typeOptionPB.field_2.id),
              (err) => Log.error("Failed creating field $err"),
            );
          },
          insertRight: () async {
            final result = await TypeOptionBackendService.createFieldTypeOption(
              viewId: viewId,
              position: CreateFieldPosition.After,
              targetFieldId: field.id,
            );
            result.fold(
              (typeOptionPB) => onFieldInserted?.call(typeOptionPB.field_2.id),
              (err) => Log.error("Failed creating field $err"),
            );
          },
          toggleFieldVisibility: () async {
            final currentVisibility =
                state.field.visibility ?? FieldVisibility.AlwaysShown;
            final newVisibility =
                currentVisibility == FieldVisibility.AlwaysHidden
                    ? FieldVisibility.AlwaysShown
                    : FieldVisibility.AlwaysHidden;
            final result = await fieldSettingsService.updateFieldSettings(
              fieldId: state.field.id,
              fieldVisibility: newVisibility,
            );
            _logIfError(result);
          },
          deleteField: () async {
            final result = await fieldService.deleteField();
            _logIfError(result);
          },
          duplicateField: () async {
            final result = await fieldService.duplicateField();
            _logIfError(result);
          },
        );
      },
    );
  }

  void _logIfError(Either<Unit, FlowyError> result) {
    result.fold(
      (l) => null,
      (err) => Log.error(err),
    );
  }

  @override
  Future<void> close() {
    _singleFieldListener.stop();

    return super.close();
  }
}

@freezed
class FieldEditorEvent with _$FieldEditorEvent {
  const factory FieldEditorEvent.initial() = _InitialField;
  const factory FieldEditorEvent.didReceiveFieldChanged(final String fieldId) =
      _DidReceiveFieldChanged;
  const factory FieldEditorEvent.switchFieldType(final FieldType fieldType) =
      _SwitchFieldType;
  const factory FieldEditorEvent.renameField(final String name) = _RenameField;
  const factory FieldEditorEvent.insertLeft() = _InsertLeft;
  const factory FieldEditorEvent.insertRight() = _InsertRight;
  const factory FieldEditorEvent.toggleFieldVisibility() =
      _ToggleFieldVisiblity;
  const factory FieldEditorEvent.deleteField() = _DeleteField;
  const factory FieldEditorEvent.duplicateField() = _DuplicateField;
}

@freezed
class FieldEditorState with _$FieldEditorState {
  const factory FieldEditorState({
    required final FieldInfo field,
  }) = _FieldEditorState;
}
