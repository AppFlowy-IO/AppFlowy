import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field_service.dart';

part 'field_edit_bloc.freezed.dart';

class FieldEditBloc extends Bloc<FieldEditEvent, FieldEditState> {
  final FieldService service;

  FieldEditBloc({required Field field, required this.service}) : super(FieldEditState.initial(field)) {
    on<FieldEditEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialField value) {},
          createField: (_CreateField value) {},
          updateFieldName: (_UpdateFieldName value) {
            //
          },
          hideField: (_HideField value) {},
          deleteField: (_DeleteField value) {},
          insertField: (_InsertField value) {},
          duplicateField: (_DuplicateField value) {},
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
class FieldEditEvent with _$FieldEditEvent {
  const factory FieldEditEvent.initial() = _InitialField;
  const factory FieldEditEvent.createField() = _CreateField;
  const factory FieldEditEvent.updateFieldName(String name) = _UpdateFieldName;
  const factory FieldEditEvent.hideField() = _HideField;
  const factory FieldEditEvent.duplicateField() = _DuplicateField;
  const factory FieldEditEvent.insertField({required bool onLeft}) = _InsertField;
  const factory FieldEditEvent.deleteField() = _DeleteField;
}

@freezed
class FieldEditState with _$FieldEditState {
  const factory FieldEditState({
    required Field field,
    required String errorText,
  }) = _FieldEditState;

  factory FieldEditState.initial(Field field) => FieldEditState(
        field: field,
        errorText: '',
      );
}
