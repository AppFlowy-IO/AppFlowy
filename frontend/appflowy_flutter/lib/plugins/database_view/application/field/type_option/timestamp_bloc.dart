import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/timestamp_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

import 'type_option_context.dart';
part 'timestamp_bloc.freezed.dart';

class TimestampTypeOptionBloc
    extends Bloc<TimestampTypeOptionEvent, TimestampTypeOptionState> {
  TimestampTypeOptionBloc({
    required TimestampTypeOptionContext typeOptionContext,
  }) : super(TimestampTypeOptionState.initial(typeOptionContext.typeOption)) {
    on<TimestampTypeOptionEvent>(
      (event, emit) async {
        event.map(
          didSelectDateFormat: (_DidSelectDateFormat value) {
            _updateTypeOption(dateFormat: value.format, emit: emit);
          },
          didSelectTimeFormat: (_DidSelectTimeFormat value) {
            _updateTypeOption(timeFormat: value.format, emit: emit);
          },
          includeTime: (_IncludeTime value) {
            _updateTypeOption(includeTime: value.includeTime, emit: emit);
          },
        );
      },
    );
  }

  void _updateTypeOption({
    DateFormatPB? dateFormat,
    TimeFormatPB? timeFormat,
    bool? includeTime,
    required Emitter<TimestampTypeOptionState> emit,
  }) {
    state.typeOption.freeze();
    final newTypeOption = state.typeOption.rebuild((typeOption) {
      if (dateFormat != null) {
        typeOption.dateFormat = dateFormat;
      }

      if (timeFormat != null) {
        typeOption.timeFormat = timeFormat;
      }

      if (includeTime != null) {
        typeOption.includeTime = includeTime;
      }
    });
    emit(state.copyWith(typeOption: newTypeOption));
  }
}

@freezed
class TimestampTypeOptionEvent with _$TimestampTypeOptionEvent {
  const factory TimestampTypeOptionEvent.didSelectDateFormat(
    DateFormatPB format,
  ) = _DidSelectDateFormat;
  const factory TimestampTypeOptionEvent.didSelectTimeFormat(
    TimeFormatPB format,
  ) = _DidSelectTimeFormat;
  const factory TimestampTypeOptionEvent.includeTime(bool includeTime) =
      _IncludeTime;
}

@freezed
class TimestampTypeOptionState with _$TimestampTypeOptionState {
  const factory TimestampTypeOptionState({
    required TimestampTypeOptionPB typeOption,
  }) = _TimestampTypeOptionState;

  factory TimestampTypeOptionState.initial(TimestampTypeOptionPB typeOption) =>
      TimestampTypeOptionState(typeOption: typeOption);
}
