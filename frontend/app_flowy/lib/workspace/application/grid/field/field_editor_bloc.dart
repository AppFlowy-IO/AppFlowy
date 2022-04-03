import 'dart:typed_data';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field_service.dart';
import 'package:dartz/dartz.dart';

part 'field_editor_bloc.freezed.dart';

class FieldEditorBloc extends Bloc<FieldEditorEvent, FieldEditorState> {
  final FieldService service;
  final FieldContextLoader _loader;

  FieldEditorBloc({
    required this.service,
    required FieldContextLoader fieldLoader,
  })  : _loader = fieldLoader,
        super(FieldEditorState.initial(service.gridId)) {
    on<FieldEditorEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialField value) async {
            await _getEditFieldContext(emit);
          },
          updateName: (_UpdateName value) {
            emit(state.copyWith(fieldName: value.name));
          },
          switchField: (_SwitchField value) {
            emit(state.copyWith(field: Some(value.field), typeOptionData: value.typeOptionData));
          },
          done: (_Done value) async {
            await _saveField(emit);
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }

  Future<void> _saveField(Emitter<FieldEditorState> emit) async {
    await state.field.fold(
      () async => null,
      (field) async {
        field.name = state.fieldName;
        final result = await service.createField(
          field: field,
          typeOptionData: state.typeOptionData,
        );
        result.fold((l) => null, (r) => null);
      },
    );
  }

  Future<void> _getEditFieldContext(Emitter<FieldEditorState> emit) async {
    final result = await _loader.load();
    result.fold(
      (editContext) {
        emit(state.copyWith(
          field: Some(editContext.gridField),
          typeOptionData: editContext.typeOptionData,
          fieldName: editContext.gridField.name,
        ));
      },
      (err) => Log.error(err),
    );
  }
}

@freezed
class FieldEditorEvent with _$FieldEditorEvent {
  const factory FieldEditorEvent.initial() = _InitialField;
  const factory FieldEditorEvent.updateName(String name) = _UpdateName;
  const factory FieldEditorEvent.switchField(Field field, Uint8List typeOptionData) = _SwitchField;
  const factory FieldEditorEvent.done() = _Done;
}

@freezed
class FieldEditorState with _$FieldEditorState {
  const factory FieldEditorState({
    required String fieldName,
    required String gridId,
    required String errorText,
    required Option<Field> field,
    required List<int> typeOptionData,
  }) = _FieldEditorState;

  factory FieldEditorState.initial(String gridId) => FieldEditorState(
        gridId: gridId,
        fieldName: '',
        field: none(),
        errorText: '',
        typeOptionData: List<int>.empty(),
      );
}
