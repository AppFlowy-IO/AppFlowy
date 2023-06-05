import 'package:appflowy_backend/protobuf/flowy-database/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_setting_bloc.freezed.dart';

typedef DayOfWeek = int;

class CalendarSettingBloc
    extends Bloc<CalendarSettingEvent, CalendarSettingState> {
  CalendarSettingBloc({required final CalendarLayoutSettingsPB? layoutSettings})
      : super(CalendarSettingState.initial(layoutSettings)) {
    on<CalendarSettingEvent>((final event, final emit) {
      event.when(
        performAction: (final action) {
          emit(state.copyWith(selectedAction: Some(action)));
        },
        updateLayoutSetting: (final setting) {
          emit(state.copyWith(layoutSetting: Some(setting)));
        },
      );
    });
  }
}

@freezed
class CalendarSettingState with _$CalendarSettingState {
  const factory CalendarSettingState({
    required final Option<CalendarSettingAction> selectedAction,
    required final Option<CalendarLayoutSettingsPB> layoutSetting,
  }) = _CalendarSettingState;

  factory CalendarSettingState.initial(
    final CalendarLayoutSettingsPB? layoutSettings,
  ) =>
      CalendarSettingState(
        selectedAction: none(),
        layoutSetting: layoutSettings == null ? none() : Some(layoutSettings),
      );
}

@freezed
class CalendarSettingEvent with _$CalendarSettingEvent {
  const factory CalendarSettingEvent.performAction(
    final CalendarSettingAction action,
  ) = _PerformAction;
  const factory CalendarSettingEvent.updateLayoutSetting(
    final CalendarLayoutSettingsPB setting,
  ) = _UpdateLayoutSetting;
}

enum CalendarSettingAction {
  properties,
  layout,
}
