import 'dart:collection';

import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
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

part 'calendar_bloc.freezed.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final DatabaseController _databaseController;

  // Getters
  String get viewId => _databaseController.viewId;
  CellCache get cellCache => _databaseController.rowCache.cellCache;

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
            _loadEvents();
          },
          didReceiveCalendarSettings: (CalendarLayoutSettingsPB settings) {
            emit(state.copyWith(settings: Some(settings)));
          },
          didReceiveDatabaseUpdate: (DatabasePB database) {
            emit(state.copyWith(database: Some(database)));
          },
          didReceiveEvents: (events) {
            emit(state.copyWith(events: events));
          },
          createEvent: (DateTime date) {
            final timestamp = (date.millisecondsSinceEpoch ~/ 1000);
          },
        );
      },
    );
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

  Future<void> _loadEvents() async {
    final payload = CalendarEventRequestPB.create()..viewId = viewId;
    DatabaseEventGetCalendarEvents(payload).send().then((result) {
      result.fold(
        (events) {
          if (!isClosed) {
            final calendarEvents = <CalendarEventData<CalendarCardData>>[];
            final fieldInfoByFieldId =
                LinkedHashMap<String, FieldInfo>.fromIterable(
              _databaseController.fieldController.fieldInfos,
              key: (fieldInfo) => fieldInfo.field.id,
              value: (fieldInfo) => fieldInfo,
            );

            for (final event in events.items) {
              final fieldInfo = fieldInfoByFieldId[event.fieldId];
              if (fieldInfo != null) {
                final cellId = CellIdentifier(
                  viewId: viewId,
                  rowId: event.rowId,
                  fieldInfo: fieldInfo,
                );

                final eventData = CalendarCardData(
                  event: event,
                  cellId: cellId,
                );

                // Will use the actual date later
                // final date = DateTime.fromMillisecondsSinceEpoch(
                //   calendarEvent.timestamp.toInt(),
                // );
                final calendarEvent = CalendarEventData(
                  title: event.title,
                  date: DateTime.now(),
                  event: eventData,
                );

                calendarEvents.add(calendarEvent);
              }
            }

            add(CalendarEvent.didReceiveEvents(calendarEvents));
          }
        },
        (r) => Log.error(r),
      );
    });
  }

  RowCache? getRowCache(String blockId) {
    return _databaseController.rowCache;
  }

  void _startListening() {
    final onDatabaseChanged = DatabaseCallbacks(
      onDatabaseChanged: (database) {
        if (isClosed) return;
      },
    );

    final onLayoutChanged = LayoutCallbacks(
      onLayoutChanged: _didReceiveLayout,
      onLoadLayout: _didReceiveLayout,
    );

    _databaseController.addListener(
      onDatabaseChanged: onDatabaseChanged,
      onLayoutChanged: onLayoutChanged,
    );
  }

  void _didReceiveLayout(LayoutSettingPB layoutSetting) {
    if (layoutSetting.hasCalendar()) {
      if (isClosed) return;
      add(CalendarEvent.didReceiveCalendarSettings(layoutSetting.calendar));
    }
  }
}

@freezed
class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent.initial() = _InitialCalendar;
  const factory CalendarEvent.didReceiveCalendarSettings(
      CalendarLayoutSettingsPB settings) = _DidReceiveCalendarSettings;
  const factory CalendarEvent.didReceiveEvents(
          List<CalendarEventData<CalendarCardData>> events) =
      _DidReceiveCalendarEvents;
  const factory CalendarEvent.createEvent(DateTime date) = _CreateEvent;
  const factory CalendarEvent.didReceiveDatabaseUpdate(DatabasePB database) =
      _DidReceiveDatabaseUpdate;
}

@freezed
class CalendarState with _$CalendarState {
  const factory CalendarState({
    required String databaseId,
    required Option<DatabasePB> database,
    required List<CalendarEventData<CalendarCardData>> events,
    required Option<CalendarLayoutSettingsPB> settings,
    required DatabaseLoadingState loadingState,
    required Option<FlowyError> noneOrError,
  }) = _CalendarState;

  factory CalendarState.initial(String databaseId) => CalendarState(
        database: none(),
        databaseId: databaseId,
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
