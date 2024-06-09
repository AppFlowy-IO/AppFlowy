import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/domain/layout_setting_listener.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'calendar_setting_bloc.freezed.dart';

class CalendarSettingBloc
    extends Bloc<CalendarSettingEvent, CalendarSettingState> {
  CalendarSettingBloc({required DatabaseController databaseController})
      : _databaseController = databaseController,
        _listener = DatabaseLayoutSettingListener(databaseController.viewId),
        super(
          CalendarSettingState.initial(
            databaseController.databaseLayoutSetting?.calendar,
          ),
        ) {
    _dispatch();
  }

  final DatabaseController _databaseController;
  final DatabaseLayoutSettingListener _listener;

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _dispatch() {
    on<CalendarSettingEvent>((event, emit) {
      event.when(
        initial: () {
          _startListening();
        },
        didUpdateLayoutSetting: (CalendarLayoutSettingPB setting) {
          emit(state.copyWith(layoutSetting: layoutSetting));
        },
        updateLayoutSetting: (
          bool? showWeekends,
          bool? showWeekNumbers,
          int? firstDayOfWeek,
          String? layoutFieldId,
        ) {
          _updateLayoutSettings(
            showWeekends,
            showWeekNumbers,
            firstDayOfWeek,
            layoutFieldId,
            emit,
          );
        },
      );
    });
  }

  void _updateLayoutSettings(
    bool? showWeekends,
    bool? showWeekNumbers,
    int? firstDayOfWeek,
    String? layoutFieldId,
    Emitter<CalendarSettingState> emit,
  ) {
    final currentSetting = state.layoutSetting;
    if (currentSetting == null) {
      return;
    }
    currentSetting.freeze();
    final newSetting = currentSetting.rebuild((setting) {
      if (showWeekends != null) {
        setting.showWeekends = !showWeekends;
      }

      if (showWeekNumbers != null) {
        setting.showWeekNumbers = !showWeekNumbers;
      }

      if (firstDayOfWeek != null) {
        setting.firstDayOfWeek = firstDayOfWeek;
      }

      if (layoutFieldId != null) {
        setting.fieldId = layoutFieldId;
      }
    });

    _databaseController.updateLayoutSetting(
      calendarLayoutSetting: newSetting,
    );
    emit(state.copyWith(layoutSetting: newSetting));
  }

  CalendarLayoutSettingPB? get layoutSetting =>
      _databaseController.databaseLayoutSetting?.calendar;

  void _startListening() {
    _listener.start(
      onLayoutChanged: (result) {
        if (isClosed) {
          return;
        }

        result.fold(
          (setting) => add(
            CalendarSettingEvent.didUpdateLayoutSetting(setting.calendar),
          ),
          (r) => Log.error(r),
        );
      },
    );
  }
}

@freezed
class CalendarSettingState with _$CalendarSettingState {
  const factory CalendarSettingState({
    required CalendarLayoutSettingPB? layoutSetting,
  }) = _CalendarSettingState;

  factory CalendarSettingState.initial(
    CalendarLayoutSettingPB? layoutSettings,
  ) {
    return CalendarSettingState(layoutSetting: layoutSettings);
  }
}

@freezed
class CalendarSettingEvent with _$CalendarSettingEvent {
  const factory CalendarSettingEvent.initial() = _Initial;
  const factory CalendarSettingEvent.didUpdateLayoutSetting(
    CalendarLayoutSettingPB setting,
  ) = _DidUpdateLayoutSetting;
  const factory CalendarSettingEvent.updateLayoutSetting({
    bool? showWeekends,
    bool? showWeekNumbers,
    int? firstDayOfWeek,
    String? layoutFieldId,
  }) = _UpdateLayoutSetting;
}
