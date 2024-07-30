import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/user/application/reminder/reminder_service.dart';
import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/notification/notification_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_bloc.freezed.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  ReminderBloc() : super(ReminderState()) {
    _actionBloc = getIt<ActionNavigationBloc>();
    _reminderService = const ReminderService();
    timer = _periodicCheck();

    _dispatch();
  }

  late final ActionNavigationBloc _actionBloc;
  late final ReminderService _reminderService;
  late final Timer timer;

  void _dispatch() {
    on<ReminderEvent>(
      (event, emit) async {
        await event.when(
          markAllRead: () async {
            final unreadReminders =
                state.pastReminders.where((reminder) => !reminder.isRead);

            final reminders = [...state.reminders];
            final updatedReminders = <ReminderPB>[];
            for (final reminder in unreadReminders) {
              reminders.remove(reminder);

              reminder.isRead = true;
              await _reminderService.updateReminder(reminder: reminder);

              updatedReminders.add(reminder);
            }

            reminders.addAll(updatedReminders);
            emit(state.copyWith(reminders: reminders));
          },
          started: () async {
            final remindersOrFailure = await _reminderService.fetchReminders();

            remindersOrFailure.fold(
              (reminders) => emit(state.copyWith(reminders: reminders)),
              (error) => Log.error(error),
            );
          },
          remove: (reminderId) async {
            final unitOrFailure =
                await _reminderService.removeReminder(reminderId: reminderId);

            unitOrFailure.fold(
              (_) {
                final reminders = [...state.reminders];
                reminders.removeWhere((e) => e.id == reminderId);
                emit(state.copyWith(reminders: reminders));
              },
              (error) => Log.error(error),
            );
          },
          add: (reminder) async {
            final unitOrFailure =
                await _reminderService.addReminder(reminder: reminder);

            return unitOrFailure.fold(
              (_) {
                final reminders = [...state.reminders, reminder];
                emit(state.copyWith(reminders: reminders));
              },
              (error) => Log.error(error),
            );
          },
          addById: (reminderId, objectId, scheduledAt, meta) async => add(
            ReminderEvent.add(
              reminder: ReminderPB(
                id: reminderId,
                objectId: objectId,
                title: LocaleKeys.reminderNotification_title.tr(),
                message: LocaleKeys.reminderNotification_message.tr(),
                scheduledAt: scheduledAt,
                isAck: scheduledAt.toDateTime().isBefore(DateTime.now()),
                meta: meta,
              ),
            ),
          ),
          update: (updateObject) async {
            final reminder = state.reminders
                .firstWhereOrNull((r) => r.id == updateObject.id);

            if (reminder == null) {
              return;
            }

            final newReminder = updateObject.merge(a: reminder);
            final failureOrUnit = await _reminderService.updateReminder(
              reminder: updateObject.merge(a: reminder),
            );

            failureOrUnit.fold(
              (_) {
                final index =
                    state.reminders.indexWhere((r) => r.id == reminder.id);
                final reminders = [...state.reminders];
                reminders.replaceRange(index, index + 1, [newReminder]);
                emit(state.copyWith(reminders: reminders));
              },
              (error) => Log.error(error),
            );
          },
          pressReminder: (reminderId, path, view) {
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

            String? rowId;
            if (view?.layout != ViewLayoutPB.Document) {
              rowId = reminder.meta[ReminderMetaKeys.rowId];
            }

            final action = NavigationAction(
              objectId: reminder.objectId,
              arguments: {
                ActionArgumentKeys.view: view,
                ActionArgumentKeys.nodePath: path,
                ActionArgumentKeys.rowId: rowId,
              },
            );

            if (!isClosed) {
              _actionBloc.add(
                ActionNavigationEvent.performAction(
                  action: action,
                  nextActions: [
                    action.copyWith(
                      type: rowId != null
                          ? ActionType.openRow
                          : ActionType.jumpToBlock,
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  Timer _periodicCheck() {
    return Timer.periodic(
      const Duration(minutes: 1),
      (_) async {
        final now = DateTime.now();

        for (final reminder in state.upcomingReminders) {
          if (reminder.isAck) {
            continue;
          }

          final scheduledAt = reminder.scheduledAt.toDateTime();

          if (scheduledAt.isBefore(now)) {
            final notificationSettings =
                await UserSettingsBackendService().getNotificationSettings();
            if (notificationSettings.notificationsEnabled) {
              NotificationMessage(
                identifier: reminder.id,
                title: LocaleKeys.reminderNotification_title.tr(),
                body: LocaleKeys.reminderNotification_message.tr(),
                onClick: () => _actionBloc.add(
                  ActionNavigationEvent.performAction(
                    action: NavigationAction(objectId: reminder.objectId),
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
  const factory ReminderEvent.remove({required String reminderId}) = _Remove;

  // Add a reminder
  const factory ReminderEvent.add({required ReminderPB reminder}) = _Add;

  // Add a reminder
  const factory ReminderEvent.addById({
    required String reminderId,
    required String objectId,
    required Int64 scheduledAt,
    @Default(null) Map<String, String>? meta,
  }) = _AddById;

  // Update a reminder (eg. isAck, isRead, etc.)
  const factory ReminderEvent.update(ReminderUpdate update) = _Update;

  // Mark all unread reminders as read
  const factory ReminderEvent.markAllRead() = _MarkAllRead;

  const factory ReminderEvent.pressReminder({
    required String reminderId,
    @Default(null) int? path,
    @Default(null) ViewPB? view,
  }) = _PressReminder;
}

/// Object used to merge updates with
/// a [ReminderPB]
///
class ReminderUpdate {
  ReminderUpdate({
    required this.id,
    this.isAck,
    this.isRead,
    this.scheduledAt,
    this.includeTime,
    this.isArchived,
  });

  final String id;
  final bool? isAck;
  final bool? isRead;
  final DateTime? scheduledAt;
  final bool? includeTime;
  final bool? isArchived;

  ReminderPB merge({required ReminderPB a}) {
    final isAcknowledged = isAck == null && scheduledAt != null
        ? scheduledAt!.isBefore(DateTime.now())
        : a.isAck;

    final meta = a.meta;
    if (includeTime != a.includeTime) {
      meta[ReminderMetaKeys.includeTime] = includeTime.toString();
    }

    if (isArchived != a.isArchived) {
      meta[ReminderMetaKeys.isArchived] = isArchived.toString();
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
