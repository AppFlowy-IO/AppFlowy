import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../application/database_controller.dart';
import '../../application/row/row_cache.dart';

part 'unschedule_event_bloc.freezed.dart';

class UnscheduleCalendarEventBloc
    extends Bloc<UnscheduleCalendarEvent, UnscheduleCalendarState> {
  final DatabaseController databaseController;
  Map<String, FieldInfo> fieldInfoByFieldId = {};

  // Getters
  String get viewId => databaseController.viewId;
  FieldController get fieldController => databaseController.fieldController;
  CellCache get cellCache => databaseController.rowCache.cellCache;
  RowCache get rowCache => databaseController.rowCache;

  UnscheduleCalendarEventBloc(
      {required ViewPB view, required this.databaseController})
      : super(UnscheduleCalendarState.initial()) {
    on<UnscheduleCalendarEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            _loadAllEvents();
          },
          didLoadAllEvents: (events) {
            emit(
              state.copyWith(allEvents: events),
            );
          },
          // didUpdateEvent:
          //     (UnscheduleCalendarEventData<CalendarDayEvent> eventData) {
          //   final allEvents = [...state.allEvents];
          //   final index = allEvents.indexWhere(
          //     (element) => element.event!.eventId == eventData.event!.eventId,
          //   );
          //   if (index != -1) {
          //     allEvents[index] = eventData;
          //   }
          //   emit(state.copyWith(allEvents: allEvents, updateEvent: eventData));
          // },
          didDeleteEvents: (List<RowId> deletedRowIds) {
            final events = [...state.allEvents];
            events.retainWhere(
              (element) => !deletedRowIds.contains(element.rowMeta.id),
            );
            emit(
              state.copyWith(
                allEvents: events,
              ),
            );
          },
          didReceiveEvent: (CalendarEventPB event) {
            emit(
              state.copyWith(
                allEvents: [...state.allEvents, event],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateCalendarLayoutSetting(
    CalendarLayoutSettingPB layoutSetting,
  ) async {
    return databaseController.updateCalenderLayoutSetting(layoutSetting);
  }

  Future<CalendarEventPB?> _loadEvent(
    RowId rowId,
  ) async {
    final payload = RowIdPB(viewId: viewId, rowId: rowId);
    return DatabaseEventGetCalendarEvent(payload).send().then(
          (result) => result.fold(
            (eventPB) => eventPB,
            (r) {
              Log.error(r);
              return null;
            },
          ),
        );
  }

  Future<void> _loadAllEvents() async {
    final payload = CalendarEventRequestPB.create()..viewId = viewId;
    DatabaseEventGetAllCalendarEvents(payload).send().then((result) {
      result.fold(
        (events) {
          if (!isClosed) {
            add(UnscheduleCalendarEvent.didLoadAllEvents(events.items));
          }
        },
        (r) => Log.error(r),
      );
    });
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
          for (var fieldInfo in fieldInfos) fieldInfo.field.id: fieldInfo
        };
      },
      onRowsCreated: (rowIds) async {
        if (isClosed) {
          return;
        }
        for (final id in rowIds) {
          final event = await _loadEvent(id);
          if (event != null && !isClosed) {
            add(UnscheduleCalendarEvent.didReceiveEvent(event));
          }
        }
      },
      onRowsDeleted: (rowIds) {
        if (isClosed) {
          return;
        }
        add(UnscheduleCalendarEvent.didDeleteEvents(rowIds));
      },
      onRowsUpdated: (rowIds, reason) async {
        if (isClosed) {
          return;
        }
        for (final id in rowIds) {
          final event = await _loadEvent(id);
          if (event != null) {
            add(UnscheduleCalendarEvent.didDeleteEvents([id]));
            add(UnscheduleCalendarEvent.didReceiveEvent(event));
          }
        }
      },
    );
  }
}

@freezed
class UnscheduleCalendarEvent with _$UnscheduleCalendarEvent {
  const factory UnscheduleCalendarEvent.initial() = _InitialCalendar;

  // Called after loading all the current evnets
  const factory UnscheduleCalendarEvent.didLoadAllEvents(
    List<CalendarEventPB> events,
  ) = _ReceiveUnscheduleCalendarEvents;

  const factory UnscheduleCalendarEvent.didDeleteEvents(List<RowId> rowIds) =
      _DidDeleteEvents;

  const factory UnscheduleCalendarEvent.didReceiveEvent(
    CalendarEventPB event,
  ) = _DidReceiveEvent;
}

@freezed
class UnscheduleCalendarState with _$UnscheduleCalendarState {
  const factory UnscheduleCalendarState({
    required Option<DatabasePB> database,
    required List<CalendarEventPB> allEvents,
  }) = _UnscheduleCalendarState;

  factory UnscheduleCalendarState.initial() => UnscheduleCalendarState(
        database: none(),
        allEvents: [],
      );
}
