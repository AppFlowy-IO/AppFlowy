import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/user/application/reminder/reminder_service.dart';
import 'package:appflowy/workspace/application/notifications/notification_action.dart';
import 'package:appflowy/workspace/application/notifications/notification_action_bloc.dart';
import 'package:appflowy/workspace/application/notifications/notification_service.dart';
import 'package:appflowy/workspace/application/settings/notifications/notification_settings_cubit.dart';
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
  final NotificationSettingsCubit _notificationSettings;

  late final NotificationActionBloc actionBloc;
  late final ReminderService reminderService;
  late final Timer timer;

  ReminderBloc({
    required NotificationSettingsCubit notificationSettings,
  })  : _notificationSettings = notificationSettings,
        super(ReminderState()) {
    actionBloc = getIt<NotificationActionBloc>();
    reminderService = const ReminderService();
    timer = _periodicCheck();

    on<ReminderEvent>((event, emit) async {
      await event.when(
        markAllRead: () async {
          final unreadReminders =
              state.pastReminders.where((reminder) => !reminder.isRead);

          final reminders = [...state.reminders];
          final updatedReminders = <ReminderPB>[];
          for (final reminder in unreadReminders) {
            reminders.remove(reminder);

            reminder.isRead = true;
            await reminderService.updateReminder(reminder: reminder);

            updatedReminders.add(reminder);
          }

          reminders.addAll(updatedReminders);
          emit(state.copyWith(reminders: reminders));
        },
        started: () async {
          final remindersOrFailure = await reminderService.fetchReminders();

          remindersOrFailure.fold(
            (error) => Log.error(error),
            (reminders) => emit(state.copyWith(reminders: reminders)),
          );
        },
        remove: (reminder) async {
          final unitOrFailure =
              await reminderService.removeReminder(reminderId: reminder.id);

          unitOrFailure.fold(
            (error) => Log.error(error),
            (_) {
              final reminders = [...state.reminders];
              reminders.removeWhere((e) => e.id == reminder.id);
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
              final reminders = [...state.reminders, reminder];
              emit(state.copyWith(reminders: reminders));
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
        pressReminder: (reminderId, path) {
          final reminder =
              state.reminders.firstWhereOrNull((r) => r.id == reminderId);

          if (reminder == null) {
            return;
          }

          add(
            ReminderEvent.update(
              ReminderUpdate(
                id: reminderId,
                isRead: state.pastReminders.contains(reminder),
              ),
            ),
          );

          actionBloc.add(
            NotificationActionEvent.performAction(
              action: NotificationAction(
                objectId: reminder.objectId,
                arguments: {
                  ActionArgumentKeys.nodePath.name: path,
                },
              ),
            ),
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

        for (final reminder in state.upcomingReminders) {
          if (reminder.isAck) {
            continue;
          }

          final scheduledAt = DateTime.fromMillisecondsSinceEpoch(
            reminder.scheduledAt.toInt() * 1000,
          );

          if (scheduledAt.isBefore(now)) {
            if (_notificationSettings.state.isNotificationsEnabled) {
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
            }

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
  const factory ReminderEvent.remove({required ReminderPB reminder}) = _Remove;

  // Add a reminder
  const factory ReminderEvent.add({required ReminderPB reminder}) = _Add;

  // Update a reminder (eg. isAck, isRead, etc.)
  const factory ReminderEvent.update(ReminderUpdate update) = _Update;

  // Mark all unread reminders as read
  const factory ReminderEvent.markAllRead() = _MarkAllRead;

  const factory ReminderEvent.pressReminder({
    required String reminderId,
    @Default(null) int? path,
  }) = _PressReminder;
}

/// Object used to merge updates with
/// a [ReminderPB]
///
class ReminderUpdate {
  final String id;
  final bool? isAck;
  final bool? isRead;
  final DateTime? scheduledAt;
  final bool? includeTime;

  ReminderUpdate({
    required this.id,
    this.isAck,
    this.isRead,
    this.scheduledAt,
    this.includeTime,
  });

  ReminderPB merge({required ReminderPB a}) {
    final isAcknowledged = isAck == null && scheduledAt != null
        ? scheduledAt!.isBefore(DateTime.now())
        : a.isAck;

    final meta = a.meta;
    if (includeTime != a.includeTime) {
      meta[ReminderMetaKeys.includeTime.name] = includeTime.toString();
    }

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
      meta: meta,
    );
  }
}

class ReminderState {
  ReminderState({List<ReminderPB>? reminders}) {
    _reminders = reminders ?? [];

    pastReminders = [];
    upcomingReminders = [];

    if (_reminders.isEmpty) {
      hasUnreads = false;
      return;
    }

    final now = DateTime.now();

    bool hasUnreadReminders = false;
    for (final reminder in _reminders) {
      final scheduledDate = DateTime.fromMillisecondsSinceEpoch(
        reminder.scheduledAt.toInt() * 1000,
      );

      if (scheduledDate.isBefore(now)) {
        pastReminders.add(reminder);

        if (!hasUnreadReminders && !reminder.isRead) {
          hasUnreadReminders = true;
        }
      } else {
        upcomingReminders.add(reminder);
      }
    }

    hasUnreads = hasUnreadReminders;
  }

  late final List<ReminderPB> _reminders;
  List<ReminderPB> get reminders => _reminders;

  late final List<ReminderPB> pastReminders;
  late final List<ReminderPB> upcomingReminders;
  late final bool hasUnreads;

  ReminderState copyWith({List<ReminderPB>? reminders}) =>
      ReminderState(reminders: reminders ?? _reminders);
}
