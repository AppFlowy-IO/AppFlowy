import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
part 'field_option_pannel_bloc.freezed.dart';

class FieldOptionPannelBloc extends Bloc<FieldOptionPannelEvent, FieldOptionPannelState> {
  FieldOptionPannelBloc({required List<SelectOption> options}) : super(FieldOptionPannelState.initial(options)) {
    on<FieldOptionPannelEvent>(
      (event, emit) async {
        await event.map(
          createOption: (_CreateOption value) async {
            emit(state.copyWith(isEditingOption: false, newOptionName: Some(value.optionName)));
          },
          beginAddingOption: (_BeginAddingOption value) {
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
class FieldOptionPannelEvent with _$FieldOptionPannelEvent {
  const factory FieldOptionPannelEvent.createOption(String optionName) = _CreateOption;
  const factory FieldOptionPannelEvent.beginAddingOption() = _BeginAddingOption;
  const factory FieldOptionPannelEvent.endAddingOption() = _EndAddingOption;
  const factory FieldOptionPannelEvent.updateOption(SelectOption option) = _UpdateOption;
  const factory FieldOptionPannelEvent.deleteOption(SelectOption option) = _DeleteOption;
}

@freezed
class FieldOptionPannelState with _$FieldOptionPannelState {
  const factory FieldOptionPannelState({
    required List<SelectOption> options,
    required bool isEditingOption,
    required Option<String> newOptionName,
    required Option<SelectOption> updateOption,
    required Option<SelectOption> deleteOption,
  }) = _FieldOptionPannelState;

  factory FieldOptionPannelState.initial(List<SelectOption> options) => FieldOptionPannelState(
        options: options,
        isEditingOption: false,
        newOptionName: none(),
        updateOption: none(),
        deleteOption: none(),
      );
}
