import 'package:appflowy/user/application/reminder/reminder_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
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
            (_) {
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
            (_) {
              state.reminders.add(reminder);
              emit(state);
            },
          );
        },
        update: (reminderId, date) async {
          final reminder =
              state.reminders.firstWhereOrNull((r) => r.id == reminderId);

          if (reminder == null) {
            return;
          }

          final newReminder = ReminderPB(
            id: reminder.id,
            objectId: reminder.objectId,
            scheduledAt: Int64(date.millisecondsSinceEpoch ~/ 1000),
            isAck: date.isBefore(DateTime.now()),
            title: reminder.title,
            message: reminder.message,
            meta: reminder.meta,
          );

          final failureOrUnit =
              await reminderService.updateReminder(reminder: newReminder);

          failureOrUnit.fold(
            (error) => Log.error(error),
            (r) {
              final index =
                  state.reminders.indexWhere((r) => r.id == reminderId);
              final reminders = [...state.reminders];
              reminders.replaceRange(index, index + 1, [newReminder]);

              emit(state.copyWith(reminders: reminders));
            },
          );
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

  const factory ReminderEvent.update({
    required String reminderId,
    required DateTime date,
  }) = _Update;
}

class ReminderState {
  ReminderState({
    List<ReminderPB>? reminders,
  }) : reminders = reminders ?? [];

  final List<ReminderPB> reminders;

  ReminderState copyWith({List<ReminderPB>? reminders}) =>
      ReminderState(reminders: reminders ?? this.reminders);
}
