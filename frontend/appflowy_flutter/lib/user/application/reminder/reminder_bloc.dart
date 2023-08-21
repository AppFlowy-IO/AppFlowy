import 'package:appflowy/user/application/reminder/reminder_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_bloc.freezed.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  late final ReminderService reminderService;

  ReminderBloc() : super(ReminderState()) {
    reminderService = const ReminderService();

    on<ReminderEvent>((event, emit) async {
      await event.when(
        started: () async {
          final remindersOrFailure = await reminderService.fetchReminders();

          remindersOrFailure.fold(
            (error) => Log.error(error),
            (reminders) => emit(state.copyWith(reminders: reminders)),
          );
        },
        remove: (reminderId) async {
          final unitOrFailure =
              await reminderService.removeReminder(reminderId: reminderId);

          unitOrFailure.fold(
            (error) => Log.error(error),
            (r) {
              final reminders = [...state.reminders];
              reminders.removeWhere((e) => e.id == reminderId);

              emit(state.copyWith(reminders: reminders));
            },
          );
        },
        add: (reminder) async {
          final unitOrFailure =
              await reminderService.addReminder(reminder: reminder);

          return unitOrFailure.fold(
            (error) => Log.error(error),
            (r) => emit(state..reminders.add(reminder)),
          );
        },
        notify: (_) {
          // TODO(Xazin): In-app Notification should be triggered
        },
      );
    });
  }
}

@freezed
class ReminderEvent with _$ReminderEvent {
  // On startup we fetch all reminders and upcoming ones
  const factory ReminderEvent.started() = _Started;

  // Remove a reminder
  const factory ReminderEvent.remove({required String reminderId}) = _Remove;

  // Add a reminder
  const factory ReminderEvent.add({required ReminderPB reminder}) = _Add;

  // Notify of a reminder (In-app notification)
  const factory ReminderEvent.notify({required ReminderPB reminder}) = _Notify;
}

class ReminderState {
  ReminderState({
    List<ReminderPB>? reminders,
  }) : reminders = reminders ?? [];

  final List<ReminderPB> reminders;

  ReminderState copyWith({List<ReminderPB>? reminders}) =>
      ReminderState(reminders: reminders ?? this.reminders);
}
