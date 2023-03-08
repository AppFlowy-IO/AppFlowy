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

  // Getters
  String get viewId => _databaseController.viewId;
  CellCache get cellCache => _databaseController.rowCache.cellCache;
  RowCache get rowCache => _databaseController.rowCache;

  CalendarBloc({required ViewPB view})
      : _databaseController = DatabaseController(
          view: view,
          layoutType: LayoutTypePB.Calendar,
        ),
        super(CalendarState.initial(view.id)) {
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
            emit(state.copyWith(events: events));
          },
          createEvent: (DateTime date, String title) async {
            await _createEvent(date, title);
          },
          didReceiveEvent: (CalendarEventData<CalendarCardData> newEvent) {
            emit(state.copyWith(events: [...state.events, newEvent]));
          },
          didUpdateFieldInfos: (Map<String, FieldInfo> fieldInfoByFieldId) {
            emit(state.copyWith(fieldInfoByFieldId: fieldInfoByFieldId));
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
    state.settings.fold(
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

          result.fold(
            (newRow) => _loadEvent(newRow.id),
            (err) => Log.error(err),
          );
        }
      },
    );
  }

  Future<void> _loadEvent(String rowId) async {
    final payload = RowIdPB(viewId: viewId, rowId: rowId);
    DatabaseEventGetCalendarEvent(payload).send().then((result) {
      result.fold(
        (eventPB) {
          final calendarEvent = _calendarEventDataFromEventPB(eventPB);
          if (calendarEvent != null) {
            add(CalendarEvent.didReceiveEvent(calendarEvent));
          }
        },
        (r) => Log.error(r),
      );
    });
  }

  Future<void> _loadAllEvents() async {
    final payload = CalendarEventRequestPB.create()..viewId = viewId;
    DatabaseEventGetAllCalendarEvents(payload).send().then((result) {
      result.fold(
        (events) {
          if (!isClosed) {
            final calendarEvents = <CalendarEventData<CalendarCardData>>[];
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

  CalendarEventData<CalendarCardData>? _calendarEventDataFromEventPB(
      CalendarEventPB eventPB) {
    final fieldInfo = state.fieldInfoByFieldId[eventPB.titleFieldId];
    if (fieldInfo != null) {
      final cellId = CellIdentifier(
        viewId: viewId,
        rowId: eventPB.rowId,
        fieldInfo: fieldInfo,
      );

      final eventData = CalendarCardData(
        event: eventPB,
        cellId: cellId,
      );

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
      onDatabaseChanged: (database) {
        if (isClosed) return;
      },
      onFieldsChanged: (fieldInfos) {
        if (isClosed) return;
        final fieldInfoByFieldId = {
          for (var fieldInfo in fieldInfos) fieldInfo.field.id: fieldInfo
        };
        add(CalendarEvent.didUpdateFieldInfos(fieldInfoByFieldId));
      },
    );

    final onLayoutChanged = LayoutCallbacks(
      onLayoutChanged: _didReceiveLayoutSetting,
      onLoadLayout: _didReceiveLayoutSetting,
    );

    _databaseController.addListener(
      onDatabaseChanged: onDatabaseChanged,
      onLayoutChanged: onLayoutChanged,
    );
  }

  void _didReceiveLayoutSetting(LayoutSettingPB layoutSetting) {
    if (layoutSetting.hasCalendar()) {
      if (isClosed) return;
      add(CalendarEvent.didReceiveCalendarSettings(layoutSetting.calendar));
    }
  }
}

typedef Events = List<CalendarEventData<CalendarCardData>>;

@freezed
class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent.initial() = _InitialCalendar;
  const factory CalendarEvent.didReceiveCalendarSettings(
      CalendarLayoutSettingsPB settings) = _ReceiveCalendarSettings;
  const factory CalendarEvent.didLoadAllEvents(Events events) =
      _ReceiveCalendarEvents;
  const factory CalendarEvent.didReceiveEvent(
      CalendarEventData<CalendarCardData> event) = _ReceiveEvent;
  const factory CalendarEvent.didUpdateFieldInfos(
      Map<String, FieldInfo> fieldInfoByFieldId) = _DidUpdateFieldInfos;
  const factory CalendarEvent.createEvent(DateTime date, String title) =
      _CreateEvent;
  const factory CalendarEvent.didReceiveDatabaseUpdate(DatabasePB database) =
      _ReceiveDatabaseUpdate;
}

@freezed
class CalendarState with _$CalendarState {
  const factory CalendarState({
    required String databaseId,
    required Option<DatabasePB> database,
    required Events events,
    required Map<String, FieldInfo> fieldInfoByFieldId,
    required Option<CalendarLayoutSettingsPB> settings,
    required DatabaseLoadingState loadingState,
    required Option<FlowyError> noneOrError,
  }) = _CalendarState;

  factory CalendarState.initial(String databaseId) => CalendarState(
        database: none(),
        databaseId: databaseId,
        fieldInfoByFieldId: {},
        events: [],
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

class CalendarCardData {
  final CalendarEventPB event;
  final CellIdentifier cellId;
  CalendarCardData({required this.cellId, required this.event});
}
