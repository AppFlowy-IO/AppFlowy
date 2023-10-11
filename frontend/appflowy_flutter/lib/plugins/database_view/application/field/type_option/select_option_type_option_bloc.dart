import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
part 'select_option_type_option_bloc.freezed.dart';

abstract mixin class ISelectOptionAction {
  Future<List<SelectOptionPB>> Function(String) get insertOption;

  List<SelectOptionPB> Function(SelectOptionPB) get deleteOption;

  List<SelectOptionPB> Function(SelectOptionPB) get updateOption;
}

class SelectOptionTypeOptionBloc
    extends Bloc<SelectOptionTypeOptionEvent, SelectOptionTypeOptionState> {
  final ISelectOptionAction typeOptionAction;

  SelectOptionTypeOptionBloc({
    required List<SelectOptionPB> options,
    required this.typeOptionAction,
  }) : super(SelectOptionTypeOptionState.initial(options)) {
    on<SelectOptionTypeOptionEvent>(
      (event, emit) async {
        await event.when(
          createOption: (optionName) async {
            final List<SelectOptionPB> options =
                await typeOptionAction.insertOption(optionName);
            emit(state.copyWith(options: options));
          },
          addingOption: () {
            emit(state.copyWith(isEditingOption: true, newOptionName: none()));
          },
          endAddingOption: () {
            emit(state.copyWith(isEditingOption: false, newOptionName: none()));
          },
          updateOption: (option) {
            final List<SelectOptionPB> options =
                typeOptionAction.updateOption(option);
            emit(state.copyWith(options: options));
          },
          deleteOption: (option) {
            final List<SelectOptionPB> options =
                typeOptionAction.deleteOption(option);
            emit(state.copyWith(options: options));
          },
        );
      },
    );
  }
}

@freezed
class SelectOptionTypeOptionEvent with _$SelectOptionTypeOptionEvent {
  const factory SelectOptionTypeOptionEvent.createOption(String optionName) =
      _CreateOption;
  const factory SelectOptionTypeOptionEvent.addingOption() = _AddingOption;
  const factory SelectOptionTypeOptionEvent.endAddingOption() =
      _EndAddingOption;
  const factory SelectOptionTypeOptionEvent.updateOption(
    SelectOptionPB option,
  ) = _UpdateOption;
  const factory SelectOptionTypeOptionEvent.deleteOption(
    SelectOptionPB option,
  ) = _DeleteOption;
}

@freezed
class SelectOptionTypeOptionState with _$SelectOptionTypeOptionState {
  const factory SelectOptionTypeOptionState({
    required List<SelectOptionPB> options,
    required bool isEditingOption,
    required Option<String> newOptionName,
  }) = _SelectOptionTypeOptionState;

  factory SelectOptionTypeOptionState.initial(List<SelectOptionPB> options) =>
      SelectOptionTypeOptionState(
        options: options,
        isEditingOption: false,
        newOptionName: none(),
      );
}
