import 'package:flowy_sdk/protobuf/flowy-grid/format.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/number_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:protobuf/protobuf.dart';
import 'type_option_context.dart';

part 'number_bloc.freezed.dart';

class NumberTypeOptionBloc
    extends Bloc<NumberTypeOptionEvent, NumberTypeOptionState> {
  NumberTypeOptionBloc({required NumberTypeOptionContext typeOptionContext})
      : super(NumberTypeOptionState.initial(typeOptionContext.typeOption)) {
    on<NumberTypeOptionEvent>(
      (event, emit) async {
        event.map(
          didSelectFormat: (_DidSelectFormat value) {
            emit(state.copyWith(typeOption: _updateNumberFormat(value.format)));
          },
        );
      },
    );
  }

  NumberTypeOption _updateNumberFormat(NumberFormat format) {
    state.typeOption.freeze();
    return state.typeOption.rebuild((typeOption) {
      typeOption.format = format;
    });
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
class NumberTypeOptionEvent with _$NumberTypeOptionEvent {
  const factory NumberTypeOptionEvent.didSelectFormat(NumberFormat format) =
      _DidSelectFormat;
}

@freezed
class NumberTypeOptionState with _$NumberTypeOptionState {
  const factory NumberTypeOptionState({
    required NumberTypeOption typeOption,
  }) = _NumberTypeOptionState;

  factory NumberTypeOptionState.initial(NumberTypeOption typeOption) =>
      NumberTypeOptionState(
        typeOption: typeOption,
      );
}
