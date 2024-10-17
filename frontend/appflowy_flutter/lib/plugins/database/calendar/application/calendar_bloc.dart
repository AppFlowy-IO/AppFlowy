import 'package:appflowy/plugins/database/application/cell/cell_cache.dart';
import 'package:appflowy/plugins/database/application/defines.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../application/database_controller.dart';
import '../../application/row/row_cache.dart';

part 'calendar_bloc.freezed.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  CalendarBloc({required this.databaseController})
      : super(CalendarState.initial()) {
    _dispatch();
  }

  final DatabaseController databaseController;
  Map<String, FieldInfo> fieldInfoByFieldId = {};

  // Getters
  String get viewId => databaseController.viewId;
  FieldController get fieldController => databaseController.fieldController;
  CellMemCache get cellCache => databaseController.rowCache.cellCache;
  RowCache get rowCache => databaseController.rowCache;

  UserProfilePB? _userProfile;
  UserProfilePB? get userProfile => _userProfile;

  void _dispatch() {
    on<CalendarEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final result = await UserEventGetUserProfile().send();
            result.fold(
              (profile) => _userProfile = profile,
              (err) => Log.error('Failed to get user profile: $err'),
            );

            _startListening();
            await _openDatabase(emit);
            _loadAllEvents();
          },
          didReceiveCalendarSettings: (CalendarLayoutSettingPB settings) {
            // If the field id changed, reload all events
            if (state.settings?.fieldId != settings.fieldId) {
              _loadAllEvents();
            }
            emit(state.copyWith(settings: settings));
          },
          didReceiveDatabaseUpdate: (DatabasePB database) {
            emit(state.copyWith(database: database));
          },
          didLoadAllEvents: (events) {
            final calenderEvents = _calendarEventDataFromEventPBs(events);
            emit(
              state.copyWith(
                initialEvents: calenderEvents,
                allEvents: calenderEvents,
              ),
            );
          },
          createEvent: (DateTime date) async {
            await _createEvent(date);
          },
          duplicateEvent: (String viewId, String rowId) async {
            final result = await RowBackendService.duplicateRow(viewId, rowId);
            result.fold(
              (_) => null,
              (e) => Log.error('Failed to duplicate event: $e', e),
            );
          },
          deleteEvent: (String viewId, String rowId) async {
            final result = await RowBackendService.deleteRows(viewId, [rowId]);
            result.fold(
              (_) => null,
              (e) => Log.error('Failed to delete event: $e', e),
            );
          },
          newEventPopupDisplayed: () {
            emit(state.copyWith(editingEvent: null));
          },
          moveEvent: (CalendarDayEvent event, DateTime date) async {
            await _moveEvent(event, date);
          },
          didCreateEvent: (CalendarEventData<CalendarDayEvent> event) {
            emit(state.copyWith(editingEvent: event));
          },
          updateCalendarLayoutSetting:
              (CalendarLayoutSettingPB layoutSetting) async {
            await _updateCalendarLayoutSetting(layoutSetting);
          },
          didUpdateEvent: (CalendarEventData<CalendarDayEvent> eventData) {
            final allEvents = [...state.allEvents];
            final index = allEvents.indexWhere(
              (element) => element.event!.eventId == eventData.event!.eventId,
            );
            if (index != -1) {
              allEvents[index] = eventData;
            }
            emit(state.copyWith(allEvents: allEvents, updateEvent: eventData));
          },
          didDeleteEvents: (List<RowId> deletedRowIds) {
            final events = [...state.allEvents];
            events.retainWhere(
              (element) => !deletedRowIds.contains(element.event!.eventId),
            );
            emit(
              state.copyWith(
                allEvents: events,
                deleteEventIds: deletedRowIds,
              ),
            );
            emit(state.copyWith(deleteEventIds: const []));
          },
          didReceiveEvent: (CalendarEventData<CalendarDayEvent> event) {
            emit(
              state.copyWith(
                allEvents: [...state.allEvents, event],
                newEvent: event,
              ),
            );
            emit(state.copyWith(newEvent: null));
          },
          openRowDetail: (row) {
            emit(state.copyWith(openRow: row));
            emit(state.copyWith(openRow: null));
          },
        );
      },
    );
  }

  FieldInfo? _getCalendarFieldInfo(String fieldId) {
    final fieldInfos = databaseController.fieldController.fieldInfos;
    final index = fieldInfos.indexWhere(
      (element) => element.field.id == fieldId,
    );
    if (index != -1) {
      return fieldInfos[index];
    } else {
      return null;
    }
  }

  Future<void> _openDatabase(Emitter<CalendarState> emit) async {
    final result = await databaseController.open();
    result.fold(
      (database) {
        databaseController.setIsLoading(false);
        emit(
          state.copyWith(
            loadingState: LoadingState.finish(FlowyResult.success(null)),
          ),
        );
      },
      (err) => emit(
        state.copyWith(
          loadingState: LoadingState.finish(FlowyResult.failure(err)),
        ),
      ),
    );
  }

  Future<void> _createEvent(DateTime date) async {
    final settings = state.settings;
    if (settings == null) {
      Log.warn('Calendar settings not found');
      return;
    }
    final dateField = _getCalendarFieldInfo(settings.fieldId);
    if (dateField != null) {
      final newRow = await RowBackendService.createRow(
        viewId: viewId,
        withCells: (builder) => builder.insertDate(dateField, date),
      ).then(
        (result) => result.fold(
          (newRow) => newRow,
          (err) {
            Log.error(err);
            return null;
          },
        ),
      );

      if (newRow != null) {
        final event = await _loadEvent(newRow.id);
        if (event != null && !isClosed) {
          add(CalendarEvent.didCreateEvent(event));
        }
      }
    }
  }

  Future<void> _moveEvent(CalendarDayEvent event, DateTime date) async {
    final timestamp = _eventTimestamp(event, date);
    final payload = MoveCalendarEventPB(
      cellPath: CellIdPB(
        viewId: viewId,
        rowId: event.eventId,
        fieldId: event.dateFieldId,
      ),
      timestamp: timestamp,
    );
    return DatabaseEventMoveCalendarEvent(payload).send().then((result) {
      return result.fold(
        (_) async {
          final modifiedEvent = await _loadEvent(event.eventId);
          add(CalendarEvent.didUpdateEvent(modifiedEvent!));
        },
        (err) {
          Log.error(err);
          return null;
        },
      );
    });
  }

  Future<void> _updateCalendarLayoutSetting(
    CalendarLayoutSettingPB layoutSetting,
  ) async {
    return databaseController.updateLayoutSetting(
      calendarLayoutSetting: layoutSetting,
    );
  }

  Future<CalendarEventData<CalendarDayEvent>?> _loadEvent(RowId rowId) async {
    final payload = DatabaseViewRowIdPB(viewId: viewId, rowId: rowId);
    return DatabaseEventGetCalendarEvent(payload).send().fold(
      (eventPB) => _calendarEventDataFromEventPB(eventPB),
      (r) {
        Log.error(r);
        return null;
      },
    );
  }

  void _loadAllEvents() async {
    final payload = CalendarEventRequestPB.create()..viewId = viewId;
    final result = await DatabaseEventGetAllCalendarEvents(payload).send();
    result.fold(
      (events) {
        if (!isClosed) {
          add(CalendarEvent.didLoadAllEvents(events.items));
        }
      },
      (r) => Log.error(r),
    );
  }

  List<CalendarEventData<CalendarDayEvent>> _calendarEventDataFromEventPBs(
    List<CalendarEventPB> eventPBs,
  ) {
    final calendarEvents = <CalendarEventData<CalendarDayEvent>>[];
    for (final eventPB in eventPBs) {
      final event = _calendarEventDataFromEventPB(eventPB);
      if (event != null) {
        calendarEvents.add(event);
      }
    }
    return calendarEvents;
  }

  CalendarEventData<CalendarDayEvent>? _calendarEventDataFromEventPB(
    CalendarEventPB eventPB,
  ) {
    final fieldInfo = fieldInfoByFieldId[eventPB.dateFieldId];
    if (fieldInfo == null) {
      return null;
    }

    // timestamp is stored as seconds, but constructor requires milliseconds
    final date = DateTime.fromMillisecondsSinceEpoch(
      eventPB.timestamp.toInt() * 1000,
    );

    final eventData = CalendarDayEvent(
      event: eventPB,
      eventId: eventPB.rowMeta.id,
      dateFieldId: eventPB.dateFieldId,
      date: date,
    );

    return CalendarEventData(
      title: eventPB.title,
      date: date,
      event: eventData,
    );
  }

  void _startListening() {
    final onDatabaseChanged = DatabaseCallbacks(
      onDatabaseChanged: (database) {
        if (isClosed) return;
      },
      onFieldsChanged: (fieldInfos) {
        if (isClosed) {
          return;
        }
        fieldInfoByFieldId = {
          for (final fieldInfo in fieldInfos) fieldInfo.field.id: fieldInfo,
        };
      },
      onRowsCreated: (rows) async {
        if (isClosed) {
          return;
        }
        for (final row in rows) {
          if (row.isHiddenInView) {
            add(CalendarEvent.openRowDetail(row.rowMeta));
          } else {
            final event = await _loadEvent(row.rowMeta.id);
            if (event != null) {
              add(CalendarEvent.didReceiveEvent(event));
            }
          }
        }
      },
      onRowsDeleted: (rowIds) {
        if (isClosed) {
          return;
        }
        add(CalendarEvent.didDeleteEvents(rowIds));
      },
      onRowsUpdated: (rowIds, reason) async {
        if (isClosed) {
          return;
        }
        for (final id in rowIds) {
          final event = await _loadEvent(id);
          if (event != null) {
            if (isEventDayChanged(event)) {
              add(CalendarEvent.didDeleteEvents([id]));
              add(CalendarEvent.didReceiveEvent(event));
            } else {
              add(CalendarEvent.didUpdateEvent(event));
            }
          }
        }
      },
      onNumOfRowsChanged: (rows, rowById, reason) {
        reason.maybeWhen(
          updateRowsVisibility: (changeset) async {
            if (isClosed) {
              return;
            }
            for (final id in changeset.invisibleRows) {
              if (_containsEvent(id)) {
                add(CalendarEvent.didDeleteEvents([id]));
              }
            }
            for (final row in changeset.visibleRows) {
              final id = row.rowMeta.id;
              if (!_containsEvent(id)) {
                final event = await _loadEvent(id);
                if (event != null) {
                  add(CalendarEvent.didReceiveEvent(event));
                }
              }
            }
          },
          orElse: () {},
        );
      },
    );

    final onLayoutSettingsChanged = DatabaseLayoutSettingCallbacks(
      onLayoutSettingsChanged: _didReceiveLayoutSetting,
    );

    databaseController.addListener(
      onDatabaseChanged: onDatabaseChanged,
      onLayoutSettingsChanged: onLayoutSettingsChanged,
    );
  }

  void _didReceiveLayoutSetting(DatabaseLayoutSettingPB layoutSetting) {
    if (layoutSetting.hasCalendar()) {
      if (isClosed) {
        return;
      }
      add(CalendarEvent.didReceiveCalendarSettings(layoutSetting.calendar));
    }
  }

  bool isEventDayChanged(CalendarEventData<CalendarDayEvent> event) {
    final index = state.allEvents.indexWhere(
      (element) => element.event!.eventId == event.event!.eventId,
    );
    if (index == -1) {
      return false;
    }
    return state.allEvents[index].date.day != event.date.day;
  }

  bool _containsEvent(String rowId) {
    return state.allEvents.any((element) => element.event!.eventId == rowId);
  }

  Int64 _eventTimestamp(CalendarDayEvent event, DateTime date) {
    final time =
        event.date.hour * 3600 + event.date.minute * 60 + event.date.second;
    return Int64(date.millisecondsSinceEpoch ~/ 1000 + time);
  }
}

typedef Events = List<CalendarEventData<CalendarDayEvent>>;

@freezed
class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent.initial() = _InitialCalendar;

  // Called after loading the calendar layout setting from the backend
  const factory CalendarEvent.didReceiveCalendarSettings(
    CalendarLayoutSettingPB settings,
  ) = _ReceiveCalendarSettings;

  // Called after loading all the current evnets
  const factory CalendarEvent.didLoadAllEvents(List<CalendarEventPB> events) =
      _ReceiveCalendarEvents;

  // Called when specific event was updated
  const factory CalendarEvent.didUpdateEvent(
    CalendarEventData<CalendarDayEvent> event,
  ) = _DidUpdateEvent;

  // Called after creating a new event
  const factory CalendarEvent.didCreateEvent(
    CalendarEventData<CalendarDayEvent> event,
  ) = _DidReceiveNewEvent;

  // Called after creating a new event
  const factory CalendarEvent.newEventPopupDisplayed() =
      _NewEventPopupDisplayed;

  // Called when receive a new event
  const factory CalendarEvent.didReceiveEvent(
    CalendarEventData<CalendarDayEvent> event,
  ) = _DidReceiveEvent;

  // Called when deleting events
  const factory CalendarEvent.didDeleteEvents(List<RowId> rowIds) =
      _DidDeleteEvents;

  // Called when creating a new event
  const factory CalendarEvent.createEvent(DateTime date) = _CreateEvent;

  // Called when moving an event
  const factory CalendarEvent.moveEvent(CalendarDayEvent event, DateTime date) =
      _MoveEvent;

  // Called when updating the calendar's layout settings
  const factory CalendarEvent.updateCalendarLayoutSetting(
    CalendarLayoutSettingPB layoutSetting,
  ) = _UpdateCalendarLayoutSetting;

  const factory CalendarEvent.didReceiveDatabaseUpdate(DatabasePB database) =
      _ReceiveDatabaseUpdate;

  const factory CalendarEvent.duplicateEvent(String viewId, String rowId) =
      _DuplicateEvent;

  const factory CalendarEvent.deleteEvent(String viewId, String rowId) =
      _DeleteEvent;

  const factory CalendarEvent.openRowDetail(RowMetaPB row) = _OpenRowDetail;
}

@freezed
class CalendarState with _$CalendarState {
  const factory CalendarState({
    required DatabasePB? database,
    // events by row id
    required Events allEvents,
    required Events initialEvents,
    CalendarEventData<CalendarDayEvent>? editingEvent,
    CalendarEventData<CalendarDayEvent>? newEvent,
    CalendarEventData<CalendarDayEvent>? updateEvent,
    required List<String> deleteEventIds,
    required CalendarLayoutSettingPB? settings,
    required RowMetaPB? openRow,
    required LoadingState loadingState,
    required FlowyError? noneOrError,
  }) = _CalendarState;

  factory CalendarState.initial() => const CalendarState(
        database: null,
        allEvents: [],
        initialEvents: [],
        deleteEventIds: [],
        settings: null,
        openRow: null,
        noneOrError: null,
        loadingState: LoadingState.loading(),
      );
}

@freezed
class CalendarDayEvent with _$CalendarDayEvent {
  const factory CalendarDayEvent({
    required CalendarEventPB event,
    required String dateFieldId,
    required String eventId,
    required DateTime date,
  }) = _CalendarDayEvent;
}
