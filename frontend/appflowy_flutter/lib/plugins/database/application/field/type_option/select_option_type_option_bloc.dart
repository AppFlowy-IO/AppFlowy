import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'select_type_option_actions.dart';

part 'select_option_type_option_bloc.freezed.dart';

class SelectOptionTypeOptionBloc
    extends Bloc<SelectOptionTypeOptionEvent, SelectOptionTypeOptionState> {
  SelectOptionTypeOptionBloc({
    required List<SelectOptionPB> options,
    required this.typeOptionAction,
  }) : super(SelectOptionTypeOptionState.initial(options)) {
    _dispatch();
  }

  final ISelectOptionAction typeOptionAction;

  void _dispatch() {
    on<SelectOptionTypeOptionEvent>(
      (event, emit) async {
        event.when(
          createOption: (optionName) {
            final List<SelectOptionPB> options =
                typeOptionAction.insertOption(state.options, optionName);
            emit(state.copyWith(options: options));
          },
          addingOption: () {
            emit(state.copyWith(isEditingOption: true, newOptionName: null));
          },
          endAddingOption: () {
            emit(state.copyWith(isEditingOption: false, newOptionName: null));
          },
          updateOption: (option) {
            final options =
                typeOptionAction.updateOption(state.options, option);
            emit(state.copyWith(options: options));
          },
          deleteOption: (option) {
            final options =
                typeOptionAction.deleteOption(state.options, option);
            emit(state.copyWith(options: options));
          },
          reorderOption: (fromOptionId, toOptionId) {
            final options = typeOptionAction.reorderOption(
              state.options,
              fromOptionId,
              toOptionId,
            );
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
  const factory SelectOptionTypeOptionEvent.reorderOption(
    String fromOptionId,
    String toOptionId,
  ) = _ReorderOption;
}

@freezed
class SelectOptionTypeOptionState with _$SelectOptionTypeOptionState {
  const factory SelectOptionTypeOptionState({
    required List<SelectOptionPB> options,
    required bool isEditingOption,
    required String? newOptionName,
  }) = _SelectOptionTypeOptionState;

  factory SelectOptionTypeOptionState.initial(List<SelectOptionPB> options) =>
      SelectOptionTypeOptionState(
        options: options,
        isEditingOption: false,
        newOptionName: null,
      );
}
