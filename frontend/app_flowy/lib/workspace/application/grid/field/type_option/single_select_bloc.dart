import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import 'type_option_service.dart';

part 'single_select_bloc.freezed.dart';

class SingleSelectTypeOptionBloc extends Bloc<SingleSelectTypeOptionEvent, SingleSelectTypeOptionState> {
  final TypeOptionService service;

  SingleSelectTypeOptionBloc(SingleSelectTypeOption typeOption, String fieldId)
      : service = TypeOptionService(fieldId: fieldId),
        super(SingleSelectTypeOptionState.initial(typeOption)) {
    on<SingleSelectTypeOptionEvent>(
      (event, emit) async {
        await event.map(
          createOption: (_CreateOption value) async {
            final result = await service.createOption(value.optionName);
            result.fold(
              (option) {
                state.typeOption.options.insert(0, option);
                emit(state);
              },
              (err) => Log.error(err),
            );
          },
          updateOptions: (_UpdateOptions value) async {},
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
class SingleSelectTypeOptionEvent with _$SingleSelectTypeOptionEvent {
  const factory SingleSelectTypeOptionEvent.createOption(String optionName) = _CreateOption;
  const factory SingleSelectTypeOptionEvent.updateOptions(List<SelectOption> options) = _UpdateOptions;
}

@freezed
class SingleSelectTypeOptionState with _$SingleSelectTypeOptionState {
  const factory SingleSelectTypeOptionState({
    required SingleSelectTypeOption typeOption,
  }) = _SingleSelectTypeOptionState;

  factory SingleSelectTypeOptionState.initial(SingleSelectTypeOption typeOption) => SingleSelectTypeOptionState(
        typeOption: typeOption,
      );
}
