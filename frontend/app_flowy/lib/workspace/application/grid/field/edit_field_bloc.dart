import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field_service.dart';

part 'edit_field_bloc.freezed.dart';

class EditFieldBloc extends Bloc<EditFieldEvent, EditFieldState> {
  final FieldService service;

  EditFieldBloc({required Field field, required this.service})
      : super(EditFieldState.initial(EditFieldContext.create()..gridField = field)) {
    on<EditFieldEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialField value) {},
          updateFieldName: (_UpdateFieldName value) {
            //
          },
          hideField: (_HideField value) {},
          deleteField: (_DeleteField value) {},
          duplicateField: (_DuplicateField value) {},
          saveField: (_SaveField value) {},
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
class EditFieldEvent with _$EditFieldEvent {
  const factory EditFieldEvent.initial() = _InitialField;
  const factory EditFieldEvent.updateFieldName(String name) = _UpdateFieldName;
  const factory EditFieldEvent.hideField() = _HideField;
  const factory EditFieldEvent.duplicateField() = _DuplicateField;
  const factory EditFieldEvent.deleteField() = _DeleteField;
  const factory EditFieldEvent.saveField() = _SaveField;
}

@freezed
class EditFieldState with _$EditFieldState {
  const factory EditFieldState({
    required EditFieldContext editContext,
    required String errorText,
  }) = _EditFieldState;

  factory EditFieldState.initial(EditFieldContext editContext) => EditFieldState(
        editContext: editContext,
        errorText: '',
      );
}
