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
  late final NotificationActionBloc actionBloc;
  late final ReminderService reminderService;
  late final Timer timer;

  ReminderBloc() : super(ReminderState()) {
    actionBloc = getIt<NotificationActionBloc>();
    reminderService = const ReminderService();
    timer = _periodicCheck();

    on<ReminderEvent>((event, emit) async {
      await event.when(
        started: () async {
          final remindersOrFailure = await reminderService.fetchReminders();

          remindersOrFailure.fold(
            (error) => Log.error(error),
            (reminders) => _updateState(emit, reminders),
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
              _updateState(emit, reminders);
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
              _updateState(emit, state.reminders);
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
              _updateState(emit, reminders);
            },
          );
        },
        pressReminder: (reminderId) {
          final reminder =
              state.reminders.firstWhereOrNull((r) => r.id == reminderId);

          if (reminder == null) {
            return;
          }

          add(
            ReminderEvent.update(ReminderUpdate(id: reminderId, isRead: true)),
          );

          actionBloc.add(
            NotificationActionEvent.performAction(
              action: NotificationAction(objectId: reminder.objectId),
            ),
          );
        },
      );
    });
  }

  void _updateState(Emitter emit, List<ReminderPB> reminders) {
    final now = DateTime.now();
    final hasUnreads = reminders.any(
      (r) =>
          DateTime.fromMillisecondsSinceEpoch(r.scheduledAt.toInt() * 1000)
              .isBefore(now) &&
          !r.isRead,
    );
    emit(state.copyWith(reminders: reminders, hasUnreads: hasUnreads));
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
              onClick: () => actionBloc.add(
                NotificationActionEvent.performAction(
                  action: NotificationAction(objectId: reminder.objectId),
                ),
              ),
            );

            add(
              ReminderEvent.update(
                ReminderUpdate(id: reminder.id, isAck: true),
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

  // Update a reminder (eg. isAck, isRead, etc.)
  const factory ReminderEvent.update(ReminderUpdate update) = _Update;

  const factory ReminderEvent.pressReminder({required String reminderId}) =
      _PressReminder;
}

/// Object used to merge updates with
/// a [ReminderPB]
///
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

  ReminderPB merge({required ReminderPB a}) {
    final isAcknowledged = isAck == null && scheduledAt != null
        ? scheduledAt!.isBefore(DateTime.now())
        : a.isAck;

    return ReminderPB(
      id: a.id,
      objectId: a.objectId,
      scheduledAt: scheduledAt != null
          ? Int64(scheduledAt!.millisecondsSinceEpoch ~/ 1000)
          : a.scheduledAt,
      isAck: isAcknowledged,
      isRead: isRead ?? a.isRead,
      title: a.title,
      message: a.message,
      meta: a.meta,
    );
  }
}

class ReminderState {
  ReminderState({
    List<ReminderPB>? reminders,
    bool? hasUnreads,
  })  : reminders = reminders ?? [],
        hasUnreads = hasUnreads ?? false;

  final List<ReminderPB> reminders;
  final bool hasUnreads;

  ReminderState copyWith({
    List<ReminderPB>? reminders,
    bool? hasUnreads,
  }) =>
      ReminderState(
        reminders: reminders ?? this.reminders,
        hasUnreads: hasUnreads ?? this.hasUnreads,
      );
}
