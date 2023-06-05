import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-database/protobuf.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../application/database_controller.dart';
import '../../application/row/row_cache.dart';

part 'calendar_bloc.freezed.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final DatabaseController _databaseController;
  Map<String, FieldInfo> fieldInfoByFieldId = {};

  // Getters
  String get viewId => _databaseController.viewId;
  FieldController get fieldController => _databaseController.fieldController;
  CellCache get cellCache => _databaseController.rowCache.cellCache;
  RowCache get rowCache => _databaseController.rowCache;

  CalendarBloc({required final ViewPB view})
      : _databaseController = DatabaseController(
          view: view,
          layoutType: LayoutTypePB.Calendar,
        ),
        super(CalendarState.initial()) {
    on<CalendarEvent>(
      (final event, final emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _openDatabase(emit);
            _loadAllEvents();
          },
          didReceiveCalendarSettings: (final CalendarLayoutSettingsPB settings) {
            emit(state.copyWith(settings: Some(settings)));
          },
          didReceiveDatabaseUpdate: (final DatabasePB database) {
            emit(state.copyWith(database: Some(database)));
          },
          didLoadAllEvents: (final events) {
            final calenderEvents = _calendarEventDataFromEventPBs(events);
            emit(
              state.copyWith(
                initialEvents: calenderEvents,
                allEvents: calenderEvents,
              ),
            );
          },
          didReceiveNewLayoutField: (final CalendarLayoutSettingsPB layoutSettings) {
            _loadAllEvents();
            emit(state.copyWith(settings: Some(layoutSettings)));
          },
          createEvent: (final DateTime date, final String title) async {
            await _createEvent(date, title);
          },
          didCreateEvent: (final CalendarEventData<CalendarDayEvent> event) {
            emit(
              state.copyWith(editEvent: event),
            );
          },
          updateCalendarLayoutSetting:
              (final CalendarLayoutSettingsPB layoutSetting) async {
            await _updateCalendarLayoutSetting(layoutSetting);
          },
          didUpdateEvent: (final CalendarEventData<CalendarDayEvent> eventData) {
            final allEvents = [...state.allEvents];
            final index = allEvents.indexWhere(
              (final element) => element.event!.eventId == eventData.event!.eventId,
            );
            if (index != -1) {
              allEvents[index] = eventData;
            }
            emit(
              state.copyWith(
                allEvents: allEvents,
              ),
            );
          },
          didDeleteEvents: (final List<String> deletedRowIds) {
            final events = [...state.allEvents];
            events.retainWhere(
              (final element) => !deletedRowIds.contains(element.event!.eventId),
            );
            emit(
              state.copyWith(
                allEvents: events,
                deleteEventIds: deletedRowIds,
              ),
            );
          },
          didReceiveEvent: (final CalendarEventData<CalendarDayEvent> event) {
            emit(
              state.copyWith(
                allEvents: [...state.allEvents, event],
                newEvent: event,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _databaseController.dispose();
    return super.close();
  }

  FieldInfo? _getCalendarFieldInfo(final String fieldId) {
    final fieldInfos = _databaseController.fieldController.fieldInfos;
    final index = fieldInfos.indexWhere(
      (final element) => element.field.id == fieldId,
    );
    if (index != -1) {
      return fieldInfos[index];
    } else {
      return null;
    }
  }

  FieldInfo? _getTitleFieldInfo() {
    final fieldInfos = _databaseController.fieldController.fieldInfos;
    final index = fieldInfos.indexWhere(
      (final element) => element.field.isPrimary,
    );
    if (index != -1) {
      return fieldInfos[index];
    } else {
      return null;
    }
  }

  Future<void> _openDatabase(final Emitter<CalendarState> emit) async {
    final result = await _databaseController.open();
    result.fold(
      (final database) => emit(
        state.copyWith(loadingState: DatabaseLoadingState.finish(left(unit))),
      ),
      (final err) => emit(
        state.copyWith(loadingState: DatabaseLoadingState.finish(right(err))),
      ),
    );
  }

  Future<void> _createEvent(final DateTime date, final String title) async {
    return state.settings.fold(
      () => null,
      (final settings) async {
        final dateField = _getCalendarFieldInfo(settings.layoutFieldId);
        final titleField = _getTitleFieldInfo();
        if (dateField != null && titleField != null) {
          final newRow = await _databaseController.createRow(
            withCells: (final builder) {
              builder.insertDate(dateField, date);
              builder.insertText(titleField, title);
            },
          ).then(
            (final result) => result.fold(
              (final newRow) => newRow,
              (final err) {
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
      },
    );
  }

  Future<void> _updateCalendarLayoutSetting(
    final CalendarLayoutSettingsPB layoutSetting,
  ) async {
    return _databaseController.updateCalenderLayoutSetting(layoutSetting);
  }

  Future<CalendarEventData<CalendarDayEvent>?> _loadEvent(final String rowId) async {
    final payload = RowIdPB(viewId: viewId, rowId: rowId);
    return DatabaseEventGetCalendarEvent(payload).send().then((final result) {
      return result.fold(
        (final eventPB) {
          final calendarEvent = _calendarEventDataFromEventPB(eventPB);
          return calendarEvent;
        },
        (final r) {
          Log.error(r);
          return null;
        },
      );
    });
  }

  Future<void> _loadAllEvents() async {
    final payload = CalendarEventRequestPB.create()..viewId = viewId;
    DatabaseEventGetAllCalendarEvents(payload).send().then((final result) {
      result.fold(
        (final events) {
          if (!isClosed) {
            add(CalendarEvent.didLoadAllEvents(events.items));
          }
        },
        (final r) => Log.error(r),
      );
    });
  }

  List<CalendarEventData<CalendarDayEvent>> _calendarEventDataFromEventPBs(
    final List<CalendarEventPB> eventPBs,
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
    final CalendarEventPB eventPB,
  ) {
    final fieldInfo = fieldInfoByFieldId[eventPB.dateFieldId];
    if (fieldInfo != null) {
      final eventData = CalendarDayEvent(
        event: eventPB,
        eventId: eventPB.rowId,
        dateFieldId: eventPB.dateFieldId,
      );

      // The timestamp is using UTC in the backend, so we need to convert it
      // to local time.
      final date = DateTime.fromMillisecondsSinceEpoch(
        eventPB.timestamp.toInt() * 1000,
      );
      return CalendarEventData(
        title: eventPB.title,
        date: date,
        event: eventData,
      );
    } else {
      return null;
    }
  }

  void _startListening() {
    final onDatabaseChanged = DatabaseCallbacks(
      onDatabaseChanged: (final database) {
        if (isClosed) return;
      },
      onFieldsChanged: (final fieldInfos) {
        if (isClosed) return;
        fieldInfoByFieldId = {
          for (var fieldInfo in fieldInfos) fieldInfo.field.id: fieldInfo
        };
      },
      onRowsCreated: ((final rowIds) async {
        for (final id in rowIds) {
          final event = await _loadEvent(id);
          if (event != null && !isClosed) {
            add(CalendarEvent.didReceiveEvent(event));
          }
        }
      }),
      onRowsDeleted: (final rowIds) {
        if (isClosed) return;
        add(CalendarEvent.didDeleteEvents(rowIds));
      },
      onRowsUpdated: (final rowIds) async {
        if (isClosed) return;
        for (final id in rowIds) {
          final event = await _loadEvent(id);
          if (event != null && isEventDayChanged(event)) {
            if (isEventDayChanged(event)) {
              add(CalendarEvent.didDeleteEvents([id]));
              add(CalendarEvent.didReceiveEvent(event));
            } else {
              add(CalendarEvent.didUpdateEvent(event));
            }
          }
        }
      },
    );

    final onLayoutChanged = LayoutCallbacks(
      onLayoutChanged: _didReceiveLayoutSetting,
      onLoadLayout: _didReceiveLayoutSetting,
    );

    final onCalendarLayoutFieldChanged = CalendarLayoutCallbacks(
      onCalendarLayoutChanged: _didReceiveNewLayoutField,
    );

    _databaseController.setListener(
      onDatabaseChanged: onDatabaseChanged,
      onLayoutChanged: onLayoutChanged,
      onCalendarLayoutChanged: onCalendarLayoutFieldChanged,
    );
  }

  void _didReceiveLayoutSetting(final LayoutSettingPB layoutSetting) {
    if (layoutSetting.hasCalendar()) {
      if (isClosed) return;
      add(CalendarEvent.didReceiveCalendarSettings(layoutSetting.calendar));
    }
  }

  void _didReceiveNewLayoutField(final LayoutSettingPB layoutSetting) {
    if (layoutSetting.hasCalendar()) {
      if (isClosed) return;
      add(CalendarEvent.didReceiveNewLayoutField(layoutSetting.calendar));
    }
  }

  bool isEventDayChanged(
    final CalendarEventData<CalendarDayEvent> event,
  ) {
    final index = state.allEvents.indexWhere(
      (final element) => element.event!.eventId == event.event!.eventId,
    );
    if (index != -1) {
      return state.allEvents[index].date.day != event.date.day;
    } else {
      return false;
    }
  }
}

typedef Events = List<CalendarEventData<CalendarDayEvent>>;

@freezed
class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent.initial() = _InitialCalendar;

  // Called after loading the calendar layout setting from the backend
  const factory CalendarEvent.didReceiveCalendarSettings(
    final CalendarLayoutSettingsPB settings,
  ) = _ReceiveCalendarSettings;

  // Called after loading all the current evnets
  const factory CalendarEvent.didLoadAllEvents(final List<CalendarEventPB> events) =
      _ReceiveCalendarEvents;

  // Called when specific event was updated
  const factory CalendarEvent.didUpdateEvent(
    final CalendarEventData<CalendarDayEvent> event,
  ) = _DidUpdateEvent;

  // Called after creating a new event
  const factory CalendarEvent.didCreateEvent(
    final CalendarEventData<CalendarDayEvent> event,
  ) = _DidReceiveNewEvent;

  // Called when receive a new event
  const factory CalendarEvent.didReceiveEvent(
    final CalendarEventData<CalendarDayEvent> event,
  ) = _DidReceiveEvent;

  // Called when deleting events
  const factory CalendarEvent.didDeleteEvents(final List<String> rowIds) =
      _DidDeleteEvents;

  // Called when creating a new event
  const factory CalendarEvent.createEvent(final DateTime date, final String title) =
      _CreateEvent;

  // Called when updating the calendar's layout settings
  const factory CalendarEvent.updateCalendarLayoutSetting(
    final CalendarLayoutSettingsPB layoutSetting,
  ) = _UpdateCalendarLayoutSetting;

  const factory CalendarEvent.didReceiveDatabaseUpdate(final DatabasePB database) =
      _ReceiveDatabaseUpdate;

  const factory CalendarEvent.didReceiveNewLayoutField(
    final CalendarLayoutSettingsPB layoutSettings,
  ) = _DidReceiveNewLayoutField;
}

@freezed
class CalendarState with _$CalendarState {
  const factory CalendarState({
    required final Option<DatabasePB> database,
    // events by row id
    required final Events allEvents,
    required final Events initialEvents,
    final CalendarEventData<CalendarDayEvent>? editEvent,
    final CalendarEventData<CalendarDayEvent>? newEvent,
    required final List<String> deleteEventIds,
    required final Option<CalendarLayoutSettingsPB> settings,
    required final DatabaseLoadingState loadingState,
    required final Option<FlowyError> noneOrError,
  }) = _CalendarState;

  factory CalendarState.initial() => CalendarState(
        database: none(),
        allEvents: [],
        initialEvents: [],
        deleteEventIds: [],
        settings: none(),
        noneOrError: none(),
        loadingState: const _Loading(),
      );
}

@freezed
class DatabaseLoadingState with _$DatabaseLoadingState {
  const factory DatabaseLoadingState.loading() = _Loading;
  const factory DatabaseLoadingState.finish(
    final Either<Unit, FlowyError> successOrFail,
  ) = _Finish;
}

class CalendarEditingRow {
  RowPB row;
  int? index;

  CalendarEditingRow({
    required this.row,
    required this.index,
  });
}

class CalendarDayEvent {
  final CalendarEventPB event;
  final String dateFieldId;
  final String eventId;

  CalendarDayEvent({
    required this.dateFieldId,
    required this.eventId,
    required this.event,
  });
}
