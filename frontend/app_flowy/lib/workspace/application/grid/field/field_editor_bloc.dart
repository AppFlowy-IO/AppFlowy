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
  final String gridId;
  final FieldContextLoader _loader;

  FieldEditorBloc({
    required this.gridId,
    required FieldContextLoader fieldLoader,
  })  : _loader = fieldLoader,
        super(FieldEditorState.initial(gridId)) {
    on<FieldEditorEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialField value) async {
            await _getFieldTypeOptionContext(emit);
          },
          updateName: (_UpdateName value) {
            final newContext = _updateEditContext(name: value.name);
            emit(state.copyWith(fieldTypeOptionData: newContext));
          },
          updateField: (_UpdateField value) {
            final data = _updateEditContext(field: value.field, typeOptionData: value.typeOptionData);
            emit(state.copyWith(fieldTypeOptionData: data));
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

  Option<FieldTypeOptionData> _updateEditContext({
    String? name,
    Field? field,
    List<int>? typeOptionData,
  }) {
    return state.fieldTypeOptionData.fold(
      () => none(),
      (context) {
        context.freeze();
        final newFieldTypeOptionData = context.rebuild((newContext) {
          newContext.field_2.rebuild((newField) {
            if (name != null) {
              newField.name = name;
            }

            newContext.field_2 = newField;
          });

          if (field != null) {
            newContext.field_2 = field;
          }

          if (typeOptionData != null) {
            newContext.typeOptionData = typeOptionData;
          }
        });

        FieldService.insertField(
          gridId: gridId,
          field: newFieldTypeOptionData.field_2,
          typeOptionData: newFieldTypeOptionData.typeOptionData,
        );

        return Some(newFieldTypeOptionData);
      },
    );
  }

  Future<void> _saveField(Emitter<FieldEditorState> emit) async {
    await state.fieldTypeOptionData.fold(
      () async => null,
      (data) async {
        final result = await FieldService.insertField(
          gridId: gridId,
          field: data.field_2,
          typeOptionData: data.typeOptionData,
        );
        result.fold((l) => null, (r) => null);
      },
    );
  }

  Future<void> _getFieldTypeOptionContext(Emitter<FieldEditorState> emit) async {
    final result = await _loader.load();
    result.fold(
      (context) {
        emit(state.copyWith(
          fieldTypeOptionData: Some(context),
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
    required Option<FieldTypeOptionData> fieldTypeOptionData,
  }) = _FieldEditorState;

  factory FieldEditorState.initial(String gridId) => FieldEditorState(
        gridId: gridId,
        fieldTypeOptionData: none(),
        errorText: '',
      );
}
