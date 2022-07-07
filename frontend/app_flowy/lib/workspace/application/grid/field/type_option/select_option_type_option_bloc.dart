import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
part 'select_option_type_option_bloc.freezed.dart';

abstract class SelectOptionTypeOptionAction {
  Future<List<SelectOption>> Function(String) get insertOption;

  List<SelectOption> Function(SelectOption) get deleteOption;

  List<SelectOption> Function(SelectOption) get udpateOption;
}

class SelectOptionTypeOptionBloc extends Bloc<SelectOptionTypeOptionEvent, SelectOptionTypeOptionState> {
  final SelectOptionTypeOptionAction typeOptionAction;

  SelectOptionTypeOptionBloc({
    required List<SelectOption> options,
    required this.typeOptionAction,
  }) : super(SelectOptionTypeOptionState.initial(options)) {
    on<SelectOptionTypeOptionEvent>(
      (event, emit) async {
        await event.when(
          createOption: (optionName) async {
            final List<SelectOption> options = await typeOptionAction.insertOption(optionName);
            emit(state.copyWith(options: options));
          },
          addingOption: () {
            emit(state.copyWith(isEditingOption: true, newOptionName: none()));
          },
          endAddingOption: () {
            emit(state.copyWith(isEditingOption: false, newOptionName: none()));
          },
          updateOption: (option) {
            final List<SelectOption> options = typeOptionAction.udpateOption(option);
            emit(state.copyWith(options: options));
          },
          deleteOption: (option) {
            final List<SelectOption> options = typeOptionAction.deleteOption(option);
            emit(state.copyWith(options: options));
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
class SelectOptionTypeOptionState with _$SelectOptionTypeOptionState {
  const factory SelectOptionTypeOptionState({
    required List<SelectOption> options,
    required bool isEditingOption,
    required Option<String> newOptionName,
  }) = _SelectOptionTyepOptionState;

  factory SelectOptionTypeOptionState.initial(List<SelectOption> options) => SelectOptionTypeOptionState(
        options: options,
        isEditingOption: false,
        newOptionName: none(),
      );
}
