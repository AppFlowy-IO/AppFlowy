import 'dart:typed_data';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

part 'multi_select_bloc.freezed.dart';

class MultiSelectTypeOptionBloc extends Bloc<MultiSelectTypeOptionEvent, MultiSelectTypeOptionState> {
  MultiSelectTypeOptionBloc(MultiSelectTypeOption typeOption) : super(MultiSelectTypeOptionState.initial(typeOption)) {
    on<MultiSelectTypeOptionEvent>(
      (event, emit) async {
        await event.map(
          createOption: (_CreateOption value) {},
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
class MultiSelectTypeOptionEvent with _$MultiSelectTypeOptionEvent {
  const factory MultiSelectTypeOptionEvent.createOption(String optionName) = _CreateOption;
  const factory MultiSelectTypeOptionEvent.updateOptions(List<SelectOption> options) = _UpdateOptions;
}

@freezed
class MultiSelectTypeOptionState with _$MultiSelectTypeOptionState {
  const factory MultiSelectTypeOptionState({
    required MultiSelectTypeOption typeOption,
  }) = _MultiSelectTypeOptionState;

  factory MultiSelectTypeOptionState.initial(MultiSelectTypeOption typeOption) => MultiSelectTypeOptionState(
        typeOption: typeOption,
      );
}
