import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'field_service.dart';
import 'package:dartz/dartz.dart';
part 'field_editor_bloc.freezed.dart';

class FieldEditorBloc extends Bloc<FieldEditorEvent, FieldEditorState> {
  FieldEditorBloc({
    required String gridId,
    required String fieldName,
    required FieldContextLoader fieldContextLoader,
  }) : super(FieldEditorState.initial(gridId, fieldName, fieldContextLoader)) {
    on<FieldEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final fieldContext = GridFieldContext(gridId: gridId, loader: fieldContextLoader);
            await fieldContext.loadData().then((result) {
              result.fold(
                (l) => emit(state.copyWith(fieldContext: Some(fieldContext))),
                (r) => null,
              );
            });
          },
          updateName: (name) {
            state.fieldContext.fold(() => null, (fieldContext) => fieldContext.fieldName = name);
            emit(state.copyWith(name: name));
          },
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
class FieldEditorEvent with _$FieldEditorEvent {
  const factory FieldEditorEvent.initial() = _InitialField;
  const factory FieldEditorEvent.updateName(String name) = _UpdateName;
}

@freezed
class FieldEditorState with _$FieldEditorState {
  const factory FieldEditorState({
    required String gridId,
    required String errorText,
    required String name,
    required Option<GridFieldContext> fieldContext,
  }) = _FieldEditorState;

  factory FieldEditorState.initial(String gridId, String fieldName, FieldContextLoader loader) => FieldEditorState(
        gridId: gridId,
        fieldContext: none(),
        errorText: '',
        name: fieldName,
      );
}
