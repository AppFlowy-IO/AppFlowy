import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:protobuf/protobuf.dart';
import 'package:dartz/dartz.dart';
part 'edit_select_option_bloc.freezed.dart';

class EditSelectOptionBloc extends Bloc<EditSelectOptionEvent, EditSelectOptionState> {
  EditSelectOptionBloc({required SelectOption option}) : super(EditSelectOptionState.initial(option)) {
    on<EditSelectOptionEvent>(
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
class EditSelectOptionEvent with _$EditSelectOptionEvent {
  const factory EditSelectOptionEvent.updateName(String name) = _UpdateName;
  const factory EditSelectOptionEvent.updateColor(SelectOptionColor color) = _UpdateColor;
  const factory EditSelectOptionEvent.delete() = _Delete;
}

@freezed
class EditSelectOptionState with _$EditSelectOptionState {
  const factory EditSelectOptionState({
    required SelectOption option,
    required Option<bool> deleted,
  }) = _EditSelectOptionState;

  factory EditSelectOptionState.initial(SelectOption option) => EditSelectOptionState(
        option: option,
        deleted: none(),
      );
}
