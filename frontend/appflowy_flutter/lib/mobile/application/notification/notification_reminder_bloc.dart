import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_reminder_bloc.freezed.dart';

class NotificationReminderBloc
    extends Bloc<NotificationReminderEvent, NotificationReminderState> {
  NotificationReminderBloc() : super(const NotificationReminderState()) {
    on<NotificationReminderEvent>((event, emit) async {
      event.when(
        reset: () => emit(const NotificationReminderState()),
        toggleShowUnreadsOnly: () => emit(
          state.copyWith(showUnreadsOnly: !state.showUnreadsOnly),
        ),
      );
    });
  }
}

@freezed
class NotificationReminderEvent with _$NotificationReminderEvent {
  const factory NotificationReminderEvent.toggleShowUnreadsOnly() =
      _ToggleShowUnreadsOnly;

  const factory NotificationReminderEvent.reset() = _Reset;
}

@freezed
class NotificationReminderState with _$NotificationReminderState {
  const NotificationReminderState._();

  const factory NotificationReminderState({
    @Default(false) bool showUnreadsOnly,
  }) = _NotificationReminderState;

  // If state is not default values, then there are custom changes
  bool get hasFilters => showUnreadsOnly != false;
}
