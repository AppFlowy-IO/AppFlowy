import 'package:app_flowy/workspace/application/grid/field/type_option/type_option_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:protobuf/protobuf.dart';
part 'date_bloc.freezed.dart';

typedef DateTypeOptionContext = TypeOptionWidgetContext<DateTypeOption>;

class DateTypeOptionDataParser extends TypeOptionDataParser<DateTypeOption> {
  @override
  DateTypeOption fromBuffer(List<int> buffer) {
    return DateTypeOption.fromBuffer(buffer);
  }
}

class DateTypeOptionBloc extends Bloc<DateTypeOptionEvent, DateTypeOptionState> {
  DateTypeOptionBloc({required DateTypeOptionContext typeOptionContext})
      : super(DateTypeOptionState.initial(typeOptionContext.typeOption)) {
    on<DateTypeOptionEvent>(
      (event, emit) async {
        event.map(
          didSelectDateFormat: (_DidSelectDateFormat value) {
            emit(state.copyWith(typeOption: _updateTypeOption(dateFormat: value.format)));
          },
          didSelectTimeFormat: (_DidSelectTimeFormat value) {
            emit(state.copyWith(typeOption: _updateTypeOption(timeFormat: value.format)));
          },
          includeTime: (_IncludeTime value) {
            emit(state.copyWith(typeOption: _updateTypeOption(includeTime: value.includeTime)));
          },
        );
      },
    );
  }

  DateTypeOption _updateTypeOption({
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

  @override
  Future<void> close() async {
    return super.close();
  }
}

@freezed
class DateTypeOptionEvent with _$DateTypeOptionEvent {
  const factory DateTypeOptionEvent.didSelectDateFormat(DateFormat format) = _DidSelectDateFormat;
  const factory DateTypeOptionEvent.didSelectTimeFormat(TimeFormat format) = _DidSelectTimeFormat;
  const factory DateTypeOptionEvent.includeTime(bool includeTime) = _IncludeTime;
}

@freezed
class DateTypeOptionState with _$DateTypeOptionState {
  const factory DateTypeOptionState({
    required DateTypeOption typeOption,
  }) = _DateTypeOptionState;

  factory DateTypeOptionState.initial(DateTypeOption typeOption) => DateTypeOptionState(typeOption: typeOption);
}
