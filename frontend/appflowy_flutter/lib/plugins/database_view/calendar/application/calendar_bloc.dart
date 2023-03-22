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

  CalendarBloc({required ViewPB view})
      : _databaseController = DatabaseController(
          view: view,
          layoutType: LayoutTypePB.Calendar,
        ),
        super(CalendarState.initial()) {
    on<CalendarEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _openDatabase(emit);
            _loadAllEvents();
          },
          didReceiveCalendarSettings: (CalendarLayoutSettingsPB settings) {
            emit(state.copyWith(settings: Some(settings)));
          },
          didReceiveDatabaseUpdate: (DatabasePB database) {
            emit(state.copyWith(database: Some(database)));
          },
          didLoadAllEvents: (events) {
            emit(state.copyWith(initialEvents: events, allEvents: events));
          },
          didReceiveNewLayoutField: (CalendarLayoutSettingsPB layoutSettings) {
            _loadAllEvents();
            emit(state.copyWith(settings: Some(layoutSettings)));
          },
          createEvent: (DateTime date, String title) async {
            await _createEvent(date, title);
          },
          updateCalendarLayoutSetting:
              (CalendarLayoutSettingsPB layoutSetting) async {
            await _updateCalendarLayoutSetting(layoutSetting);
          },
          didUpdateEvent: (CalendarEventData<CalendarDayEvent> eventData) {
            var allEvents = [...state.allEvents];
            final index = allEvents.indexWhere(
              (element) => element.event!.cellId == eventData.event!.cellId,
            );
            if (index != -1) {
              allEvents[index] = eventData;
            }
            emit(state.copyWith(
              allEvents: allEvents,
              updateEvent: eventData,
            ));
          },
          didReceiveNewEvent: (CalendarEventData<CalendarDayEvent> event) {
            emit(state.copyWith(
              allEvents: [...state.allEvents, event],
              newEvent: event,
            ));
          },
          didDeleteEvents: (List<String> deletedRowIds) {
            var events = [...state.allEvents];
            events.retainWhere(
              (element) => !deletedRowIds.contains(element.event!.cellId.rowId),
            );
            emit(
              state.copyWith(
                allEvents: events,
                deleteEventIds: deletedRowIds,
              ),
            );
          },
        );
      },
    );
  }

  FieldInfo? _getCalendarFieldInfo(String fieldId) {
    final fieldInfos = _databaseController.fieldController.fieldInfos;
    final index = fieldInfos.indexWhere(
      (element) => element.field.id == fieldId,
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
      (element) => element.field.isPrimary,
    );
    if (index != -1) {
      return fieldInfos[index];
    } else {
      return null;
    }
  }

  Future<void> _openDatabase(Emitter<CalendarState> emit) async {
    final result = await _databaseController.open();
    result.fold(
      (database) => emit(
        state.copyWith(loadingState: DatabaseLoadingState.finish(left(unit))),
      ),
      (err) => emit(
        state.copyWith(loadingState: DatabaseLoadingState.finish(right(err))),
      ),
    );
  }

  Future<void> _createEvent(DateTime date, String title) async {
    return state.settings.fold(
      () => null,
      (settings) async {
        final dateField = _getCalendarFieldInfo(settings.layoutFieldId);
        final titleField = _getTitleFieldInfo();
        if (dateField != null && titleField != null) {
          final result = await _databaseController.createRow(
            withCells: (builder) {
              builder.insertDate(dateField, date);
              builder.insertText(titleField, title);
            },
          );

          return result.fold(
            (newRow) {},
            (err) => Log.error(err),
          );
        }
      },
    );
  }

  Future<void> _updateCalendarLayoutSetting(
      CalendarLayoutSettingsPB layoutSetting) async {
    return _databaseController.updateCalenderLayoutSetting(layoutSetting);
  }

  Future<CalendarEventData<CalendarDayEvent>?> _loadEvent(String rowId) async {
    final payload = RowIdPB(viewId: viewId, rowId: rowId);
    return DatabaseEventGetCalendarEvent(payload).send().then((result) {
      return result.fold(
        (eventPB) {
          final calendarEvent = _calendarEventDataFromEventPB(eventPB);
          return calendarEvent;
        },
        (r) {
          Log.error(r);
          return null;
        },
      );
    });
  }

  Future<void> _loadAllEvents() async {
    final payload = CalendarEventRequestPB.create()..viewId = viewId;
    DatabaseEventGetAllCalendarEvents(payload).send().then((result) {
      result.fold(
        (events) {
          if (!isClosed) {
            final calendarEvents = <CalendarEventData<CalendarDayEvent>>[];
            for (final eventPB in events.items) {
              final calendarEvent = _calendarEventDataFromEventPB(eventPB);
              if (calendarEvent != null) {
                calendarEvents.add(calendarEvent);
              }
            }

            add(CalendarEvent.didLoadAllEvents(calendarEvents));
          }
        },
        (r) => Log.error(r),
      );
    });
  }

  CalendarEventData<CalendarDayEvent>? _calendarEventDataFromEventPB(
      CalendarEventPB eventPB) {
    final fieldInfo = fieldInfoByFieldId[eventPB.titleFieldId];
    if (fieldInfo != null) {
      final cellId = CellIdentifier(
        viewId: viewId,
        rowId: eventPB.rowId,
        fieldInfo: fieldInfo,
      );

      final eventData = CalendarDayEvent(
        event: eventPB,
        cellId: cellId,
      );

      final date = DateTime.fromMillisecondsSinceEpoch(
        eventPB.timestamp.toInt() * 1000,
        isUtc: true,
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
      onDatabaseChanged: (database) {
        if (isClosed) return;
      },
      onFieldsChanged: (fieldInfos) {
        if (isClosed) return;
        fieldInfoByFieldId = {
          for (var fieldInfo in fieldInfos) fieldInfo.field.id: fieldInfo
        };
      },
      onRowsChanged: ((onRowsChanged, rowByRowId, reason) {}),
      onRowsCreated: ((ids) async {
        for (final id in ids) {
          final event = await _loadEvent(id);
          if (event != null && !isClosed) {
            add(CalendarEvent.didReceiveNewEvent(event));
          }
        }
      }),
      onRowsDeleted: (ids) {
        if (isClosed) return;
        add(CalendarEvent.didDeleteEvents(ids));
      },
      onRowsUpdated: (ids) async {
        if (isClosed) return;
        for (final id in ids) {
          final event = await _loadEvent(id);
          if (event != null) {
            add(CalendarEvent.didUpdateEvent(event));
          }
        }
      },
    );

    final onLayoutChanged = LayoutCallbacks(
      onLayoutChanged: _didReceiveLayoutSetting,
      onLoadLayout: _didReceiveLayoutSetting,
    );

    final onCalendarLayoutFieldChanged = CalendarLayoutCallbacks(
        onCalendarLayoutChanged: _didReceiveNewLayoutField);

    _databaseController.addListener(
      onDatabaseChanged: onDatabaseChanged,
      onLayoutChanged: onLayoutChanged,
      onCalendarLayoutChanged: onCalendarLayoutFieldChanged,
    );
  }

  void _didReceiveLayoutSetting(LayoutSettingPB layoutSetting) {
    if (layoutSetting.hasCalendar()) {
      if (isClosed) return;
      add(CalendarEvent.didReceiveCalendarSettings(layoutSetting.calendar));
    }
  }

  void _didReceiveNewLayoutField(LayoutSettingPB layoutSetting) {
    if (layoutSetting.hasCalendar()) {
      if (isClosed) return;
      add(CalendarEvent.didReceiveNewLayoutField(layoutSetting.calendar));
    }
  }
}

typedef Events = List<CalendarEventData<CalendarDayEvent>>;

@freezed
class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent.initial() = _InitialCalendar;

  // Called after loading the calendar layout setting from the backend
  const factory CalendarEvent.didReceiveCalendarSettings(
      CalendarLayoutSettingsPB settings) = _ReceiveCalendarSettings;

  // Called after loading all the current evnets
  const factory CalendarEvent.didLoadAllEvents(Events events) =
      _ReceiveCalendarEvents;

  // Called when specific event was updated
  const factory CalendarEvent.didUpdateEvent(
      CalendarEventData<CalendarDayEvent> event) = _DidUpdateEvent;

  // Called after creating a new event
  const factory CalendarEvent.didReceiveNewEvent(
      CalendarEventData<CalendarDayEvent> event) = _DidReceiveNewEvent;

  // Called when deleting events
  const factory CalendarEvent.didDeleteEvents(List<String> rowIds) =
      _DidDeleteEvents;

  // Called when creating a new event
  const factory CalendarEvent.createEvent(DateTime date, String title) =
      _CreateEvent;

  // Called when updating the calendar's layout settings
  const factory CalendarEvent.updateCalendarLayoutSetting(
      CalendarLayoutSettingsPB layoutSetting) = _UpdateCalendarLayoutSetting;

  const factory CalendarEvent.didReceiveDatabaseUpdate(DatabasePB database) =
      _ReceiveDatabaseUpdate;

  const factory CalendarEvent.didReceiveNewLayoutField(
      CalendarLayoutSettingsPB layoutSettings) = _DidReceiveNewLayoutField;
}

@freezed
class CalendarState with _$CalendarState {
  const factory CalendarState({
    required Option<DatabasePB> database,
    required Events allEvents,
    required Events initialEvents,
    CalendarEventData<CalendarDayEvent>? newEvent,
    required List<String> deleteEventIds,
    CalendarEventData<CalendarDayEvent>? updateEvent,
    required Option<CalendarLayoutSettingsPB> settings,
    required DatabaseLoadingState loadingState,
    required Option<FlowyError> noneOrError,
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
      Either<Unit, FlowyError> successOrFail) = _Finish;
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
  final CellIdentifier cellId;

  String get eventId => cellId.rowId;
  CalendarDayEvent({required this.cellId, required this.event});
}
