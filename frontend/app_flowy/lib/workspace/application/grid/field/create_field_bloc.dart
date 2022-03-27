import 'dart:typed_data';

import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field_service.dart';
import 'package:dartz/dartz.dart';

part 'create_field_bloc.freezed.dart';

class CreateFieldBloc extends Bloc<CreateFieldEvent, CreateFieldState> {
  final FieldService service;

  CreateFieldBloc({required this.service}) : super(CreateFieldState.initial(service.gridId)) {
    on<CreateFieldEvent>(
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

  Future<void> _saveField(Emitter<CreateFieldState> emit) async {
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

  Future<void> _getEditFieldContext(Emitter<CreateFieldState> emit) async {
    final result = await service.getEditFieldContext(FieldType.RichText);
    result.fold(
      (editContext) {
        emit(state.copyWith(
          field: Some(editContext.gridField),
          typeOptionData: editContext.typeOptionData,
        ));
      },
      (err) => Log.error(err),
    );
  }
}

@freezed
class CreateFieldEvent with _$CreateFieldEvent {
  const factory CreateFieldEvent.initial() = _InitialField;
  const factory CreateFieldEvent.updateName(String name) = _UpdateName;
  const factory CreateFieldEvent.switchField(Field field, Uint8List typeOptionData) = _SwitchField;
  const factory CreateFieldEvent.done() = _Done;
}

@freezed
class CreateFieldState with _$CreateFieldState {
  const factory CreateFieldState({
    required String fieldName,
    required String gridId,
    required String errorText,
    required Option<Field> field,
    required List<int> typeOptionData,
  }) = _CreateFieldState;

  factory CreateFieldState.initial(String gridId) => CreateFieldState(
        gridId: gridId,
        fieldName: '',
        field: none(),
        errorText: '',
        typeOptionData: List<int>.empty(),
      );
}
