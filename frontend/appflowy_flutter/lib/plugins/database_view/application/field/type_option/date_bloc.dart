import 'package:appflowy_backend/protobuf/flowy-database/date_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/date_type_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

import 'type_option_context.dart';
part 'date_bloc.freezed.dart';

class DateTypeOptionBloc
    extends Bloc<DateTypeOptionEvent, DateTypeOptionState> {
  DateTypeOptionBloc({required final DateTypeOptionContext typeOptionContext})
      : super(DateTypeOptionState.initial(typeOptionContext.typeOption)) {
    on<DateTypeOptionEvent>(
      (final event, final emit) async {
        event.map(
          didSelectDateFormat: (final _DidSelectDateFormat value) {
            emit(
              state.copyWith(
                typeOption: _updateTypeOption(dateFormat: value.format),
              ),
            );
          },
          didSelectTimeFormat: (final _DidSelectTimeFormat value) {
            emit(
              state.copyWith(
                typeOption: _updateTypeOption(timeFormat: value.format),
              ),
            );
          },
          includeTime: (final _IncludeTime value) {
            emit(
              state.copyWith(
                typeOption: _updateTypeOption(includeTime: value.includeTime),
              ),
            );
          },
        );
      },
    );
  }

  DateTypeOptionPB _updateTypeOption({
    final DateFormat? dateFormat,
    final TimeFormat? timeFormat,
    final bool? includeTime,
  }) {
    state.typeOption.freeze();
    return state.typeOption.rebuild((final typeOption) {
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
  }
}

@freezed
class DateTypeOptionEvent with _$DateTypeOptionEvent {
  const factory DateTypeOptionEvent.didSelectDateFormat(final DateFormat format) =
      _DidSelectDateFormat;
  const factory DateTypeOptionEvent.didSelectTimeFormat(final TimeFormat format) =
      _DidSelectTimeFormat;
  const factory DateTypeOptionEvent.includeTime(final bool includeTime) =
      _IncludeTime;
}

@freezed
class DateTypeOptionState with _$DateTypeOptionState {
  const factory DateTypeOptionState({
    required final DateTypeOptionPB typeOption,
  }) = _DateTypeOptionState;

  factory DateTypeOptionState.initial(final DateTypeOptionPB typeOption) =>
      DateTypeOptionState(typeOption: typeOption);
}
