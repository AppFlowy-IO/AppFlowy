import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
part 'select_option_type_option_bloc.freezed.dart';

class SelectOptionTypeOptionBloc extends Bloc<SelectOptionTypeOptionEvent, SelectOptionTyepOptionState> {
  SelectOptionTypeOptionBloc({required List<SelectOption> options})
      : super(SelectOptionTyepOptionState.initial(options)) {
    on<SelectOptionTypeOptionEvent>(
      (event, emit) async {
        await event.map(
          createOption: (_CreateOption value) async {
            emit(state.copyWith(isEditingOption: true, newOptionName: Some(value.optionName)));
          },
          addingOption: (_AddingOption value) {
            emit(state.copyWith(isEditingOption: true, newOptionName: none()));
          },
          endAddingOption: (_EndAddingOption value) {
            emit(state.copyWith(isEditingOption: false, newOptionName: none()));
          },
          updateOption: (_UpdateOption value) {
            emit(state.copyWith(updateOption: Some(value.option)));
          },
          deleteOption: (_DeleteOption value) {
            emit(state.copyWith(deleteOption: Some(value.option)));
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
class SelectOptionTypeOptionEvent with _$SelectOptionTypeOptionEvent {
  const factory SelectOptionTypeOptionEvent.createOption(String optionName) = _CreateOption;
  const factory SelectOptionTypeOptionEvent.addingOption() = _AddingOption;
  const factory SelectOptionTypeOptionEvent.endAddingOption() = _EndAddingOption;
  const factory SelectOptionTypeOptionEvent.updateOption(SelectOption option) = _UpdateOption;
  const factory SelectOptionTypeOptionEvent.deleteOption(SelectOption option) = _DeleteOption;
}

@freezed
class SelectOptionTyepOptionState with _$SelectOptionTyepOptionState {
  const factory SelectOptionTyepOptionState({
    required List<SelectOption> options,
    required bool isEditingOption,
    required Option<String> newOptionName,
    required Option<SelectOption> updateOption,
    required Option<SelectOption> deleteOption,
  }) = _SelectOptionTyepOptionState;

  factory SelectOptionTyepOptionState.initial(List<SelectOption> options) => SelectOptionTyepOptionState(
        options: options,
        isEditingOption: false,
        newOptionName: none(),
        updateOption: none(),
        deleteOption: none(),
      );
}
