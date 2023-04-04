import 'package:appflowy_backend/protobuf/flowy-database/date_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/date_type_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

import 'type_option_context.dart';
part 'date_bloc.freezed.dart';

class DateTypeOptionBloc
    extends Bloc<DateTypeOptionEvent, DateTypeOptionState> {
  DateTypeOptionBloc({required DateTypeOptionContext typeOptionContext})
      : super(DateTypeOptionState.initial(typeOptionContext.typeOption)) {
    on<DateTypeOptionEvent>(
      (event, emit) async {
        event.map(
          didSelectDateFormat: (_DidSelectDateFormat value) {
            emit(state.copyWith(
                typeOption: _updateTypeOption(dateFormat: value.format)));
          },
          didSelectTimeFormat: (_DidSelectTimeFormat value) {
            emit(state.copyWith(
                typeOption: _updateTypeOption(timeFormat: value.format)));
          },
          includeTime: (_IncludeTime value) {
            emit(state.copyWith(
                typeOption: _updateTypeOption(includeTime: value.includeTime)));
          },
        );
      },
    );
  }

  DateTypeOptionPB _updateTypeOption({
    DateFormat? dateFormat,
    TimeFormat? timeFormat,
    bool? includeTime,
  }) {
    state.typeOption.freeze();
    return state.typeOption.rebuild((typeOption) {
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
  const factory DateTypeOptionEvent.didSelectDateFormat(DateFormat format) =
      _DidSelectDateFormat;
  const factory DateTypeOptionEvent.didSelectTimeFormat(TimeFormat format) =
      _DidSelectTimeFormat;
  const factory DateTypeOptionEvent.includeTime(bool includeTime) =
      _IncludeTime;
}

@freezed
class DateTypeOptionState with _$DateTypeOptionState {
  const factory DateTypeOptionState({
    required DateTypeOptionPB typeOption,
  }) = _DateTypeOptionState;

  factory DateTypeOptionState.initial(DateTypeOptionPB typeOption) =>
      DateTypeOptionState(typeOption: typeOption);
}
