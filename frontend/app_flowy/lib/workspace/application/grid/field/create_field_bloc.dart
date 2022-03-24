import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
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
          initial: (_InitialField value) {},
          updateName: (_UpdateName value) {},
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
}

@freezed
class CreateFieldState with _$CreateFieldState {
  const factory CreateFieldState({
    required String errorText,
    required Option<Field> field,
  }) = _CreateFieldState;

  factory CreateFieldState.initial() => CreateFieldState(
        field: none(),
        errorText: '',
      );
}
