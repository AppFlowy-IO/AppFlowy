import 'package:appflowy_backend/protobuf/flowy-database/format.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database/number_type_option.pb.dart';
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

  NumberTypeOptionPB _updateNumberFormat(NumberFormat format) {
    state.typeOption.freeze();
    return state.typeOption.rebuild((typeOption) {
      typeOption.format = format;
    });
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
    required NumberTypeOptionPB typeOption,
  }) = _NumberTypeOptionState;

  factory NumberTypeOptionState.initial(NumberTypeOptionPB typeOption) =>
      NumberTypeOptionState(
        typeOption: typeOption,
      );
}
