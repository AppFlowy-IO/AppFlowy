import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_service.dart';
import 'package:appflowy/workspace/application/local_notifications/notification_action.dart';
import 'package:appflowy/workspace/application/local_notifications/notification_action_bloc.dart';
import 'package:appflowy/workspace/application/local_notifications/notification_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_bloc.freezed.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  late final ReminderService reminderService;
  late final Timer timer;

  ReminderBloc() : super(ReminderState()) {
    reminderService = const ReminderService();
    timer = _periodicCheck();

    on<ReminderEvent>((event, emit) async {
      await event.when(
        started: () async {
          final remindersOrFailure = await reminderService.fetchReminders();

          remindersOrFailure.fold(
            (error) => Log.error(error),
            (reminders) {
              emit(state.copyWith(reminders: reminders));
            },
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
        update: (updateObject) async {
          final reminder =
              state.reminders.firstWhereOrNull((r) => r.id == updateObject.id);

          if (reminder == null) {
            return;
          }

          final newReminder = updateObject.merge(a: reminder);

          final failureOrUnit = await reminderService.updateReminder(
            reminder: updateObject.merge(a: reminder),
          );

          failureOrUnit.fold(
            (error) => Log.error(error),
            (_) {
              final index =
                  state.reminders.indexWhere((r) => r.id == reminder.id);
              final reminders = [...state.reminders];
              reminders.replaceRange(index, index + 1, [newReminder]);

              emit(state.copyWith(reminders: reminders));
            },
          );
        },
      );
    });
  }

  Timer _periodicCheck() {
    return Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        final now = DateTime.now();
        for (final reminder in state.reminders) {
          if (reminder.isAck) {
            continue;
          }

          final scheduledAt = DateTime.fromMillisecondsSinceEpoch(
            reminder.scheduledAt.toInt() * 1000,
          );

          if (scheduledAt.isBefore(now)) {
            NotificationMessage(
              identifier: reminder.id,
              title: LocaleKeys.reminderNotification_title.tr(),
              body: LocaleKeys.reminderNotification_message.tr(),
              onClick: () => getIt<NotificationActionBloc>().add(
                NotificationActionEvent.performAction(
                  action: NotificationAction(objectId: reminder.objectId),
                ),
              ),
            );

            add(
              ReminderEvent.update(
                update: ReminderUpdate(id: reminder.id, isAck: true),
              ),
            );
          }
        }
      },
    );
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
    required ReminderUpdate update,
  }) = _Update;
}

/// Object used to merge updates with
/// a [ReminderPB]
class ReminderUpdate {
  final String id;
  final bool? isAck;
  final bool? isRead;
  final DateTime? scheduledAt;

  ReminderUpdate({
    required this.id,
    this.isAck,
    this.isRead,
    this.scheduledAt,
  });

  ReminderPB merge({required ReminderPB a}) => ReminderPB(
        id: a.id,
        objectId: a.objectId,
        scheduledAt: scheduledAt != null
            ? Int64(scheduledAt!.millisecondsSinceEpoch ~/ 1000)
            : a.scheduledAt,
        isAck: isAck ?? a.isAck,
        isRead: isRead ?? a.isRead,
        title: a.title,
        message: a.message,
        meta: a.meta,
      );
}

class ReminderState {
  ReminderState({
    List<ReminderPB>? reminders,
  }) : reminders = reminders ?? [];

  final List<ReminderPB> reminders;

  ReminderState copyWith({List<ReminderPB>? reminders}) =>
      ReminderState(reminders: reminders ?? this.reminders);
}
