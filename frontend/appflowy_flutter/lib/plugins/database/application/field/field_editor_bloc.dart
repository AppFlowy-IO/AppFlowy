import 'dart:typed_data';

import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/domain/field_settings_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'field_controller.dart';
import 'field_info.dart';

part 'field_editor_bloc.freezed.dart';

class FieldEditorBloc extends Bloc<FieldEditorEvent, FieldEditorState> {
  FieldEditorBloc({
    required this.viewId,
    required this.fieldController,
    this.onFieldInserted,
    required FieldPB field,
  })  : fieldId = field.id,
        fieldService = FieldBackendService(
          viewId: viewId,
          fieldId: field.id,
        ),
        fieldSettingsService = FieldSettingsBackendService(viewId: viewId),
        super(FieldEditorState(field: FieldInfo.initial(field))) {
    _dispatch();
    _startListening();
    _init();
  }

  final String viewId;
  final String fieldId;
  final FieldController fieldController;
  final FieldBackendService fieldService;
  final FieldSettingsBackendService fieldSettingsService;
  final void Function(String newFieldId)? onFieldInserted;

  late final OnReceiveField _listener;

  @override
  Future<void> close() {
    fieldController.removeSingleFieldListener(
      fieldId: fieldId,
      onFieldChanged: _listener,
    );
    return super.close();
  }

  void _dispatch() {
    on<FieldEditorEvent>(
      (event, emit) async {
        await event.when(
          didUpdateField: (fieldInfo) {
            emit(state.copyWith(field: fieldInfo));
          },
          switchFieldType: (fieldType) async {
            await fieldService.updateType(fieldType: fieldType);
          },
          renameField: (newName) async {
            final result = await fieldService.updateField(name: newName);
            _logIfError(result);
          },
          updateTypeOption: (typeOptionData) async {
            final result = await FieldBackendService.updateFieldTypeOption(
              viewId: viewId,
              fieldId: fieldId,
              typeOptionData: typeOptionData,
            );
            _logIfError(result);
          },
          insertLeft: () async {
            final result = await fieldService.createBefore();
            result.fold(
              (newField) => onFieldInserted?.call(newField.id),
              (err) => Log.error("Failed creating field $err"),
            );
          },
          insertRight: () async {
            final result = await fieldService.createAfter();
            result.fold(
              (newField) => onFieldInserted?.call(newField.id),
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
          toggleWrapCellContent: () async {
            final currentWrap = state.field.wrapCellContent ?? false;
            final result = await fieldSettingsService.updateFieldSettings(
              fieldId: state.field.id,
              wrapCellContent: !currentWrap,
            );
            _logIfError(result);
          },
        );
      },
    );
  }

  void _startListening() {
    _listener = (field) {
      if (!isClosed) {
        add(FieldEditorEvent.didUpdateField(field));
      }
    };
    fieldController.addSingleFieldListener(
      fieldId,
      onFieldChanged: _listener,
    );
  }

  void _init() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!isClosed) {
      final field = fieldController.getField(fieldId);
      if (field != null) {
        add(FieldEditorEvent.didUpdateField(field));
      }
    }
  }

  void _logIfError(FlowyResult<void, FlowyError> result) {
    result.fold(
      (l) => null,
      (err) => Log.error(err),
    );
  }
}

@freezed
class FieldEditorEvent with _$FieldEditorEvent {
  const factory FieldEditorEvent.didUpdateField(final FieldInfo fieldInfo) =
      _DidUpdateField;
  const factory FieldEditorEvent.switchFieldType(final FieldType fieldType) =
      _SwitchFieldType;
  const factory FieldEditorEvent.updateTypeOption(
    final Uint8List typeOptionData,
  ) = _UpdateTypeOption;
  const factory FieldEditorEvent.renameField(final String name) = _RenameField;
  const factory FieldEditorEvent.insertLeft() = _InsertLeft;
  const factory FieldEditorEvent.insertRight() = _InsertRight;
  const factory FieldEditorEvent.toggleFieldVisibility() =
      _ToggleFieldVisiblity;
  const factory FieldEditorEvent.toggleWrapCellContent() =
      _ToggleWrapCellContent;
}

@freezed
class FieldEditorState with _$FieldEditorState {
  const factory FieldEditorState({
    required final FieldInfo field,
  }) = _FieldEditorState;
}
