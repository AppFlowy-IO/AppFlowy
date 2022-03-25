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

  CreateFieldBloc({required this.service}) : super(CreateFieldState.initial()) {
    on<CreateFieldEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialField value) async {
            final result = await service.getEditFieldContext(FieldType.RichText);
            result.fold(
              (editContext) => emit(state.copyWith(editContext: Some(editContext))),
              (err) => Log.error(err),
            );
          },
          updateName: (_UpdateName value) {},
          done: (_Done value) {},
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
class CreateFieldEvent with _$CreateFieldEvent {
  const factory CreateFieldEvent.initial() = _InitialField;
  const factory CreateFieldEvent.updateName(String newName) = _UpdateName;
  const factory CreateFieldEvent.done() = _Done;
}

@freezed
class CreateFieldState with _$CreateFieldState {
  const factory CreateFieldState({
    required String errorText,
    required Option<EditFieldContext> editContext,
  }) = _CreateFieldState;

  factory CreateFieldState.initial() => CreateFieldState(
        editContext: none(),
        errorText: '',
      );
}
