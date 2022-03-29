import 'dart:typed_data';

import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';

part 'option_pannel_bloc.freezed.dart';

class OptionPannelBloc extends Bloc<OptionPannelEvent, OptionPannelState> {
  OptionPannelBloc({required List<SelectOption> options}) : super(OptionPannelState.initial(options)) {
    on<OptionPannelEvent>(
      (event, emit) async {
        await event.map(
          createOption: (_CreateOption value) async {
            emit(state.copyWith(isAddingOption: false));
          },
          beginAddingOption: (_BeginAddingOption value) {
            emit(state.copyWith(isAddingOption: true));
          },
          endAddingOption: (_EndAddingOption value) {
            emit(state.copyWith(isAddingOption: false));
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
class OptionPannelEvent with _$OptionPannelEvent {
  const factory OptionPannelEvent.createOption(String optionName) = _CreateOption;
  const factory OptionPannelEvent.beginAddingOption() = _BeginAddingOption;
  const factory OptionPannelEvent.endAddingOption() = _EndAddingOption;
}

@freezed
class OptionPannelState with _$OptionPannelState {
  const factory OptionPannelState({
    required List<SelectOption> options,
    required bool isAddingOption,
  }) = _OptionPannelState;

  factory OptionPannelState.initial(List<SelectOption> options) => OptionPannelState(
        options: options,
        isAddingOption: false,
      );
}
