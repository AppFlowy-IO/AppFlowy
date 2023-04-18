import 'package:appflowy_backend/protobuf/flowy-database2/number_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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

  NumberTypeOptionPB _updateNumberFormat(NumberFormatPB format) {
    state.typeOption.freeze();
    return state.typeOption.rebuild((typeOption) {
      typeOption.format = format;
    });
  }
}

@freezed
class NumberTypeOptionEvent with _$NumberTypeOptionEvent {
  const factory NumberTypeOptionEvent.didSelectFormat(NumberFormatPB format) =
      _DidSelectFormat;
}

@freezed
class NumberTypeOptionState with _$NumberTypeOptionState {
  const factory NumberTypeOptionState({
    required NumberTypeOptionPB typeOption,
  }) = _NumberTypeOptionState;

  factory NumberTypeOptionState.initial(NumberTypeOptionPB typeOption) =>
      NumberTypeOptionState(
        typeOption: typeOption,
      );
}
