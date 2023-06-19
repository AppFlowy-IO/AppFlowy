import 'package:appflowy/plugins/database_view/application/layout/layout_setting_listener.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_setting_bloc.freezed.dart';

typedef DayOfWeek = int;

class CalendarSettingBloc
    extends Bloc<CalendarSettingEvent, CalendarSettingState> {
  final String viewId;
  final DatabaseLayoutSettingListener _listener;

  CalendarSettingBloc({
    required this.viewId,
    required CalendarLayoutSettingPB? layoutSettings,
  })  : _listener = DatabaseLayoutSettingListener(viewId),
        super(CalendarSettingState.initial(layoutSettings)) {
    on<CalendarSettingEvent>((event, emit) {
      event.when(
        init: () {
          _startListening();
        },
        performAction: (action) {
          emit(state.copyWith(selectedAction: Some(action)));
        },
        updateLayoutSetting: (setting) {
          emit(state.copyWith(layoutSetting: Some(setting)));
        },
      );
    });
  }

  void _startListening() {
    _listener.start(
      onLayoutChanged: (result) {
        if (isClosed) {
          return;
        }

        result.fold(
          (setting) =>
              add(CalendarSettingEvent.updateLayoutSetting(setting.calendar)),
          (r) => Log.error(r),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }
}

@freezed
class CalendarSettingEvent with _$CalendarSettingEvent {
  const factory CalendarSettingEvent.init() = _Init;
  const factory CalendarSettingEvent.performAction(
    CalendarSettingAction action,
  ) = _PerformAction;
  const factory CalendarSettingEvent.updateLayoutSetting(
    CalendarLayoutSettingPB setting,
  ) = _UpdateLayoutSetting;
}

enum CalendarSettingAction {
  properties,
  layout,
}

@freezed
class CalendarSettingState with _$CalendarSettingState {
  const factory CalendarSettingState({
    required Option<CalendarSettingAction> selectedAction,
    required Option<CalendarLayoutSettingPB> layoutSetting,
  }) = _CalendarSettingState;

  factory CalendarSettingState.initial(
    CalendarLayoutSettingPB? layoutSettings,
  ) =>
      CalendarSettingState(
        selectedAction: none(),
        layoutSetting: layoutSettings == null ? none() : Some(layoutSettings),
      );
}
