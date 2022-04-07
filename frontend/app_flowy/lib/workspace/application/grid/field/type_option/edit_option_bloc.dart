import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:protobuf/protobuf.dart';
import 'package:dartz/dartz.dart';
part 'edit_option_bloc.freezed.dart';

class EditOptionBloc extends Bloc<EditOptionEvent, EditOptionState> {
  EditOptionBloc({required SelectOption option}) : super(EditOptionState.initial(option)) {
    on<EditOptionEvent>(
      (event, emit) async {
        event.map(
          updateName: (_UpdateName value) {
            emit(state.copyWith(option: _updateName(value.name)));
          },
          updateColor: (_UpdateColor value) {
            emit(state.copyWith(option: _updateColor(value.color)));
          },
          delete: (_Delete value) {
            emit(state.copyWith(deleted: const Some(true)));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
  }

  SelectOption _updateColor(SelectOptionColor color) {
    state.option.freeze();
    return state.option.rebuild((option) {
      option.color = color;
    });
  }

  SelectOption _updateName(String name) {
    state.option.freeze();
    return state.option.rebuild((option) {
      option.name = name;
    });
  }
}

@freezed
class EditOptionEvent with _$EditOptionEvent {
  const factory EditOptionEvent.updateName(String name) = _UpdateName;
  const factory EditOptionEvent.updateColor(SelectOptionColor color) = _UpdateColor;
  const factory EditOptionEvent.delete() = _Delete;
}

@freezed
class EditOptionState with _$EditOptionState {
  const factory EditOptionState({
    required SelectOption option,
    required Option<bool> deleted,
  }) = _EditOptionState;

  factory EditOptionState.initial(SelectOption option) => EditOptionState(
        option: option,
        deleted: none(),
      );
}
