import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
part 'select_option_type_option_bloc.freezed.dart';

abstract class ISelectOptionAction {
  Future<List<SelectOptionPB>> Function(String) get insertOption;

  List<SelectOptionPB> Function(SelectOptionPB) get deleteOption;

  List<SelectOptionPB> Function(SelectOptionPB) get updateOption;
}

class SelectOptionTypeOptionBloc
    extends Bloc<SelectOptionTypeOptionEvent, SelectOptionTypeOptionState> {
  final ISelectOptionAction typeOptionAction;

  SelectOptionTypeOptionBloc({
    required final List<SelectOptionPB> options,
    required this.typeOptionAction,
  }) : super(SelectOptionTypeOptionState.initial(options)) {
    on<SelectOptionTypeOptionEvent>(
      (final event, final emit) async {
        await event.when(
          createOption: (final optionName) async {
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
          updateOption: (final option) {
            final List<SelectOptionPB> options =
                typeOptionAction.updateOption(option);
            emit(state.copyWith(options: options));
          },
          deleteOption: (final option) {
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
  const factory SelectOptionTypeOptionEvent.createOption(final String optionName) =
      _CreateOption;
  const factory SelectOptionTypeOptionEvent.addingOption() = _AddingOption;
  const factory SelectOptionTypeOptionEvent.endAddingOption() =
      _EndAddingOption;
  const factory SelectOptionTypeOptionEvent.updateOption(
    final SelectOptionPB option,
  ) = _UpdateOption;
  const factory SelectOptionTypeOptionEvent.deleteOption(
    final SelectOptionPB option,
  ) = _DeleteOption;
}

@freezed
class SelectOptionTypeOptionState with _$SelectOptionTypeOptionState {
  const factory SelectOptionTypeOptionState({
    required final List<SelectOptionPB> options,
    required final bool isEditingOption,
    required final Option<String> newOptionName,
  }) = _SelectOptionTypeOptionState;

  factory SelectOptionTypeOptionState.initial(final List<SelectOptionPB> options) =>
      SelectOptionTypeOptionState(
        options: options,
        isEditingOption: false,
        newOptionName: none(),
      );
}
