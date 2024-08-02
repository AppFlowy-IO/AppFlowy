import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/list_extension.dart';
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
import 'package:protobuf/protobuf.dart';

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
          started: () async {
            final result = await _reminderService.fetchReminders();

            result.fold(
              (reminders) {
                Log.info('Fetched reminders on startup: ${reminders.length}');
                emit(state.copyWith(reminders: reminders));
              },
              (error) => Log.error('Failed to fetch reminders: $error'),
            );
          },
          remove: (reminderId) async {
            final result = await _reminderService.removeReminder(
              reminderId: reminderId,
            );

            result.fold(
              (_) {
                Log.info('Removed reminder: $reminderId');
                final reminders = [...state.reminders];
                reminders.removeWhere((e) => e.id == reminderId);
                emit(state.copyWith(reminders: reminders));
              },
              (error) => Log.error(
                'Failed to remove reminder($reminderId): $error',
              ),
            );
          },
          add: (reminder) async {
            final result = await _reminderService.addReminder(
              reminder: reminder,
            );

            return result.fold(
              (_) {
                Log.info('Added reminder: ${reminder.id}');
                final reminders = [...state.reminders, reminder];
                emit(state.copyWith(reminders: reminders));
              },
              (error) => Log.error('Failed to add reminder: $error'),
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
            final reminder = state.reminders.firstWhereOrNull(
              (r) => r.id == updateObject.id,
            );

            if (reminder == null) {
              return;
            }

            final newReminder = updateObject.merge(a: reminder);
            final failureOrUnit = await _reminderService.updateReminder(
              reminder: newReminder,
            );

            Log.info('Updating reminder: ${reminder.id}');

            failureOrUnit.fold(
              (_) {
                Log.info('Updated reminder: ${reminder.id}');
                final index =
                    state.reminders.indexWhere((r) => r.id == reminder.id);
                final reminders = [...state.reminders];
                reminders.replaceRange(index, index + 1, [newReminder]);
                emit(state.copyWith(reminders: reminders));
              },
              (error) => Log.error(
                'Failed to update reminder(${reminder.id}): $error',
              ),
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
          markAsRead: (reminderIds) async {
            final reminders = await _onMarkAsRead(reminderIds: reminderIds);

            Log.info('Marked reminders as read: $reminderIds');

            emit(
              state.copyWith(
                reminders: reminders,
              ),
            );
          },
          archive: (reminderIds) async {
            final reminders = await _onArchived(
              isArchived: true,
              reminderIds: reminderIds,
            );

            Log.info('Archived reminders: $reminderIds');

            emit(
              state.copyWith(
                reminders: reminders,
              ),
            );
          },
          markAllRead: () async {
            final reminders = await _onMarkAsRead();

            Log.info('Marked all reminders as read');

            emit(
              state.copyWith(
                reminders: reminders,
              ),
            );
          },
          archiveAll: () async {
            final reminders = await _onArchived(isArchived: true);

            Log.info('Archived all reminders');

            emit(
              state.copyWith(
                reminders: reminders,
              ),
            );
          },
          unarchiveAll: () async {
            final reminders = await _onArchived(isArchived: false);
            emit(
              state.copyWith(
                reminders: reminders,
              ),
            );
          },
          refresh: () async {
            final result = await _reminderService.fetchReminders();

            result.fold(
              (reminders) {
                Log.info('Fetched reminders on refresh: ${reminders.length}');
                emit(state.copyWith(reminders: reminders));
              },
              (error) => Log.error('Failed to fetch reminders: $error'),
            );
          },
        );
      },
    );
  }

  /// Mark the reminder as read
  ///
  /// If the [reminderIds] is null, all unread reminders will be marked as read
  /// Otherwise, only the reminders with the given IDs will be marked as read
  Future<List<ReminderPB>> _onMarkAsRead({
    List<String>? reminderIds,
  }) async {
    final Iterable<ReminderPB> remindersToUpdate;

    if (reminderIds != null) {
      remindersToUpdate = state.reminders.where(
        (reminder) => reminderIds.contains(reminder.id) && !reminder.isRead,
      );
    } else {
      // Get all reminders that are not matching the isArchived flag
      remindersToUpdate = state.reminders.where(
        (reminder) => !reminder.isRead,
      );
    }

    for (final reminder in remindersToUpdate) {
      reminder.isRead = true;

      await _reminderService.updateReminder(reminder: reminder);
      Log.info('Mark reminder ${reminder.id} as read');
    }

    return state.reminders.map((e) {
      if (reminderIds != null && !reminderIds.contains(e.id)) {
        return e;
      }

      if (e.isRead) {
        return e;
      }

      e.freeze();
      return e.rebuild((update) {
        update.isRead = true;
      });
    }).toList();
  }

  /// Archive or unarchive reminders
  ///
  /// If the [reminderIds] is null, all reminders will be archived
  /// Otherwise, only the reminders with the given IDs will be archived or unarchived
  Future<List<ReminderPB>> _onArchived({
    required bool isArchived,
    List<String>? reminderIds,
  }) async {
    final Iterable<ReminderPB> remindersToUpdate;

    if (reminderIds != null) {
      remindersToUpdate = state.reminders.where(
        (reminder) =>
            reminderIds.contains(reminder.id) &&
            reminder.isArchived != isArchived,
      );
    } else {
      // Get all reminders that are not matching the isArchived flag
      remindersToUpdate = state.reminders.where(
        (reminder) => reminder.isArchived != isArchived,
      );
    }

    for (final reminder in remindersToUpdate) {
      reminder.isRead = isArchived;
      reminder.meta[ReminderMetaKeys.isArchived] = isArchived.toString();
      await _reminderService.updateReminder(reminder: reminder);
      Log.info('Reminder ${reminder.id} is archived: $isArchived');
    }

    return state.reminders.map((e) {
      if (reminderIds != null && !reminderIds.contains(e.id)) {
        return e;
      }

      if (e.isArchived == isArchived) {
        return e;
      }

      e.freeze();
      return e.rebuild((update) {
        update.isRead = isArchived;
        update.meta[ReminderMetaKeys.isArchived] = isArchived.toString();
      });
    }).toList();
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

  // Event to mark specific reminders as read, takes a list of reminder IDs
  const factory ReminderEvent.markAsRead(List<String> reminderIds) =
      _MarkAsRead;

  // Event to mark all unread reminders as read
  const factory ReminderEvent.markAllRead() = _MarkAllRead;

  // Event to archive specific reminders, takes a list of reminder IDs
  const factory ReminderEvent.archive(List<String> reminderIds) = _Archive;

  // Event to archive all reminders
  const factory ReminderEvent.archiveAll() = _ArchiveAll;

  // Event to unarchive all reminders
  const factory ReminderEvent.unarchiveAll() = _UnarchiveAll;

  // Event to handle reminder press action
  const factory ReminderEvent.pressReminder({
    required String reminderId,
    @Default(null) int? path,
    @Default(null) ViewPB? view,
  }) = _PressReminder;

  // Event to refresh reminders
  const factory ReminderEvent.refresh() = _Refresh;
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
    this.date,
  });

  final String id;
  final bool? isAck;
  final bool? isRead;
  final DateTime? scheduledAt;
  final bool? includeTime;
  final bool? isArchived;
  final DateTime? date;

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

    if (date != a.date && date != null) {
      meta[ReminderMetaKeys.date] = date!.millisecondsSinceEpoch.toString();
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
  List<ReminderPB> get reminders => _reminders.unique((e) => e.id);

  late final List<ReminderPB> pastReminders;
  late final List<ReminderPB> upcomingReminders;
  late final bool hasUnreads;

  ReminderState copyWith({List<ReminderPB>? reminders}) =>
      ReminderState(reminders: reminders ?? _reminders);
}
