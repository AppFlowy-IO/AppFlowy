import 'package:appflowy_backend/protobuf/flowy-database/format.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database/number_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';
import 'type_option_context.dart';

part 'number_bloc.freezed.dart';

class NumberTypeOptionBloc
    extends Bloc<NumberTypeOptionEvent, NumberTypeOptionState> {
  NumberTypeOptionBloc({required final NumberTypeOptionContext typeOptionContext})
      : super(NumberTypeOptionState.initial(typeOptionContext.typeOption)) {
    on<NumberTypeOptionEvent>(
      (final event, final emit) async {
        event.map(
          didSelectFormat: (final _DidSelectFormat value) {
            emit(state.copyWith(typeOption: _updateNumberFormat(value.format)));
          },
        );
      },
    );
  }

  NumberTypeOptionPB _updateNumberFormat(final NumberFormat format) {
    state.typeOption.freeze();
    return state.typeOption.rebuild((final typeOption) {
      typeOption.format = format;
    });
  }
}

@freezed
class NumberTypeOptionEvent with _$NumberTypeOptionEvent {
  const factory NumberTypeOptionEvent.didSelectFormat(final NumberFormat format) =
      _DidSelectFormat;
}

@freezed
class NumberTypeOptionState with _$NumberTypeOptionState {
  const factory NumberTypeOptionState({
    required final NumberTypeOptionPB typeOption,
  }) = _NumberTypeOptionState;

  factory NumberTypeOptionState.initial(final NumberTypeOptionPB typeOption) =>
      NumberTypeOptionState(
        typeOption: typeOption,
      );
}
