import 'dart:typed_data';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field_service.dart';
import 'package:dartz/dartz.dart';
import 'package:protobuf/protobuf.dart';

part 'field_editor_bloc.freezed.dart';

class FieldEditorBloc extends Bloc<FieldEditorEvent, FieldEditorState> {
  final FieldService service;
  final EditFieldContextLoader _loader;

  FieldEditorBloc({
    required this.service,
    required EditFieldContextLoader fieldLoader,
  })  : _loader = fieldLoader,
        super(FieldEditorState.initial(service.gridId)) {
    on<FieldEditorEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialField value) async {
            await _getEditFieldContext(emit);
          },
          updateName: (_UpdateName value) {
            final newContext = _updateEditContext(name: value.name);
            emit(state.copyWith(editFieldContext: newContext));
          },
          updateField: (_UpdateField value) {
            final newContext = _updateEditContext(field: value.field, typeOptionData: value.typeOptionData);

            emit(state.copyWith(editFieldContext: newContext));
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

  Option<EditFieldContext> _updateEditContext({
    String? name,
    Field? field,
    List<int>? typeOptionData,
  }) {
    return state.editFieldContext.fold(
      () => none(),
      (context) {
        context.freeze();
        final newContext = context.rebuild((newContext) {
          newContext.gridField.rebuild((newField) {
            if (name != null) {
              newField.name = name;
            }

            newContext.gridField = newField;
          });

          if (field != null) {
            newContext.gridField = field;
          }

          if (typeOptionData != null) {
            newContext.typeOptionData = typeOptionData;
          }
        });
        service.insertField(
          field: newContext.gridField,
          typeOptionData: newContext.typeOptionData,
        );

        return Some(newContext);
      },
    );
  }

  Future<void> _saveField(Emitter<FieldEditorState> emit) async {
    await state.editFieldContext.fold(
      () async => null,
      (context) async {
        final result = await service.insertField(
          field: context.gridField,
          typeOptionData: context.typeOptionData,
        );
        result.fold((l) => null, (r) => null);
      },
    );
  }

  Future<void> _getEditFieldContext(Emitter<FieldEditorState> emit) async {
    final result = await _loader.load();
    result.fold(
      (context) {
        emit(state.copyWith(
          editFieldContext: Some(context),
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
  const factory FieldEditorEvent.updateField(Field field, Uint8List typeOptionData) = _UpdateField;
  const factory FieldEditorEvent.done() = _Done;
}

@freezed
class FieldEditorState with _$FieldEditorState {
  const factory FieldEditorState({
    required String gridId,
    required String errorText,
    required Option<EditFieldContext> editFieldContext,
  }) = _FieldEditorState;

  factory FieldEditorState.initial(String gridId) => FieldEditorState(
        gridId: gridId,
        editFieldContext: none(),
        errorText: '',
      );
}
