import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/shared/list_extension.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/user/application/reminder/reminder_service.dart';
import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'reminder_bloc.freezed.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  ReminderBloc() : super(ReminderState()) {
    Log.info('ReminderBloc created');

    _actionBloc = getIt<ActionNavigationBloc>();
    _reminderService = const ReminderService();
    timer = _periodicCheck();
    _listener = AppLifecycleListener(
      onResume: () {
        if (!isClosed) {
          add(const ReminderEvent.refresh());
          add(const ReminderEvent.resetTimer());
        }
      },
    );

    _dispatch();
  }

  late final ActionNavigationBloc _actionBloc;
  late final ReminderService _reminderService;
  Timer? timer;
  late final AppLifecycleListener _listener;

  void _dispatch() {
    on<ReminderEvent>(
      (event, emit) async {
        await event.when(
          started: () async {
            Log.info('Start fetching reminders');
            final result = await _reminderService.fetchReminders();
            await result.fold(
              (reminders) async {
                final availableReminders =
                    await filterAvailableReminders(reminders);
                Log.info(
                  'Fetched reminders on startup: ${availableReminders.length}',
                );
                if (!isClosed && !emit.isDone) {
                  emit(
                    state.copyWith(
                      reminders: availableReminders,
                      serverReminders: reminders,
                    ),
                  );
                }
              },
              (error) async {
                Log.error('Failed to fetch reminders: $error');
              },
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
            // check the timestamp in the reminder
            if (reminder.createdAt == null) {
              reminder.freeze();
              reminder = reminder.rebuild((update) {
                update.meta[ReminderMetaKeys.createdAt] =
                    DateTime.now().millisecondsSinceEpoch.toString();
              });
            }

            final containReminder = [
                  ...state.serverReminders,
                  ...state.reminders,
                ].where((e) => e.id == reminder.id).firstOrNull !=
                null;
            if (containReminder) {
              Log.error('Reminder: ${reminder.id} failed to be added again');
              return;
            }

            final result = await _reminderService.addReminder(
              reminder: reminder,
            );

            return result.fold(
              (_) async {
                Log.info('Added reminder: ${reminder.id}');
                Log.info('Before adding reminder: ${state.reminders.length}');
                final reminderIds = [
                  ...state.serverReminders,
                  ...state.reminders,
                ].map((e) => e.id).toSet();
                final showRightNow = !DateTime.now()
                        .isBefore(reminder.scheduledAt.toDateTime()) &&
                    !reminder.isRead;

                if (!reminderIds.contains(reminder.id) && showRightNow) {
                  final reminders = [...state.reminders, reminder];
                  Log.info('After adding reminder: ${reminders.length}');
                  emit(state.copyWith(reminders: reminders));
                }
              },
              (error) {
                Log.error('Failed to add reminder: $error');
              },
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

            await failureOrUnit.fold((_) async {
              Log.info('Updated reminder: ${reminder.id}');
              final index =
                  state.reminders.indexWhere((r) => r.id == reminder.id);
              if (index == -1) return;
              final reminders = [...state.reminders];
              if (await checkReminderAvailable(
                reminder,
                [...state.serverReminders, ...state.reminders]
                    .map((e) => e.id)
                    .toSet(),
              )) {
                reminders.replaceRange(index, index + 1, [newReminder]);
                emit(state.copyWith(reminders: reminders));
              } else {
                reminders.removeAt(index);
                emit(state.copyWith(reminders: reminders));
              }
            }, (error) {
              Log.error(
                'Failed to update reminder(${reminder.id}): $error',
              );
            });
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

            await result.fold(
              (reminders) async {
                final availableReminders =
                    await filterAvailableReminders(reminders);
                Log.info(
                  'Fetched reminders on refresh: ${availableReminders.length}',
                );
                if (!isClosed && !emit.isDone) {
                  emit(
                    state.copyWith(
                      reminders: availableReminders,
                      serverReminders: reminders,
                    ),
                  );
                }
              },
              (error) {
                Log.error('Failed to fetch reminders: $error');
              },
            );
          },
          resetTimer: () {
            timer?.cancel();
            timer = _periodicCheck();
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    Log.info('ReminderBloc closed');
    _listener.dispose();
    timer?.cancel();
    await super.close();
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
      const Duration(seconds: 30),
      (_) async {
        if (!isClosed) add(const ReminderEvent.refresh());
      },
    );
  }

  Future<bool> checkReminderAvailable(
    ReminderPB reminder,
    Set<String> reminderIds, {
    Set<String>? removedIds,
  }) async {
    /// blockId is null means no node
    final blockId = reminder.meta[ReminderMetaKeys.blockId];
    if (blockId == null) {
      removedIds?.add(reminder.id);
      return false;
    }

    /// check if schedule time is comming
    final scheduledAt = reminder.scheduledAt.toDateTime();
    if (!DateTime.now().isAfter(scheduledAt) && !reminder.isRead) {
      return false;
    }

    /// check if view is not null
    final viewId = reminder.objectId;
    final view =
        await ViewBackendService.getView(viewId).fold((s) => s, (_) => null);
    if (view == null) {
      removedIds?.add(reminder.id);
      return false;
    }

    /// check if document is not null
    final document = await DocumentService()
        .openDocument(documentId: viewId)
        .fold((s) => s.toDocument(), (_) => null);
    if (document == null) {
      removedIds?.add(reminder.id);
      return false;
    }
    Node? searchById(Node current, String id) {
      if (current.id == id) {
        return current;
      }
      if (current.children.isNotEmpty) {
        for (final child in current.children) {
          final node = searchById(child, id);

          if (node != null) {
            return node;
          }
        }
      }
      return null;
    }

    /// check if node is not null
    final node = searchById(document.root, blockId);
    if (node == null) {
      removedIds?.add(reminder.id);
      return false;
    }
    final textInserts = node.delta?.whereType<TextInsert>();
    if (textInserts == null) return false;
    for (final text in textInserts) {
      final mention =
          text.attributes?[MentionBlockKeys.mention] as Map<String, dynamic>?;
      final reminderId = mention?[MentionBlockKeys.reminderId] as String?;
      if (reminderIds.contains(reminderId)) {
        return true;
      }
    }

    removedIds?.add(reminder.id);
    return false;
  }

  Future<List<ReminderPB>> filterAvailableReminders(
    List<ReminderPB> reminders,
  ) async {
    final List<ReminderPB> availableReminders = [];
    final reminderIds = reminders.map((e) => e.id).toSet();
    final removedIds = <String>{};
    for (final r in reminders) {
      if (await checkReminderAvailable(
        r,
        reminderIds,
        removedIds: removedIds,
      )) {
        availableReminders.add(r);
      }
    }
    for (final id in removedIds) {
      add(ReminderEvent.remove(reminderId: id));
    }
    return availableReminders;
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
  const factory ReminderEvent.resetTimer() = _ResetTimer;
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

    final meta = {...a.meta};
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
  ReminderState({
    List<ReminderPB>? reminders,
    this.serverReminders = const [],
  }) {
    _reminders = [];
    pastReminders = [];
    upcomingReminders = [];

    if (reminders?.isEmpty ?? true) {
      return;
    }

    final now = DateTime.now();

    for (final ReminderPB reminder in reminders ?? []) {
      final scheduledDate = reminder.scheduledAt.toDateTime();

      if (scheduledDate.isBefore(now)) {
        pastReminders.add(reminder);
      } else {
        upcomingReminders.add(reminder);
      }
    }

    pastReminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    upcomingReminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    _reminders
        .addAll([...List.of(pastReminders), ...List.of(upcomingReminders)]);
  }

  late final List<ReminderPB> _reminders;
  List<ReminderPB> get reminders => _reminders.unique((e) => e.id);

  late final List<ReminderPB> pastReminders;
  late final List<ReminderPB> upcomingReminders;
  final List<ReminderPB> serverReminders;

  ReminderState copyWith({
    List<ReminderPB>? reminders,
    List<ReminderPB>? serverReminders,
  }) =>
      ReminderState(
        reminders: reminders ?? _reminders,
        serverReminders: serverReminders ?? this.serverReminders,
      );
}
