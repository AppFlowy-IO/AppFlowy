import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-database/protobuf.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'calendar_data_controller.dart';

part 'calendar_bloc.freezed.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CalendarDataController _databaseDataController;
  final EventController calendarEventsController = EventController();

  FieldController get fieldController =>
      _databaseDataController.fieldController;
  String get databaseId => _databaseDataController.databaseId;

  CalendarBloc({required ViewPB view})
      : _databaseDataController = CalendarDataController(view: view),
        super(CalendarState.initial(view.id)) {
    on<CalendarEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _openDatabase(emit);
          },
          didReceiveCalendarSettings: (CalendarSettingsPB settings) {
            emit(state.copyWith(settings: Some(settings)));
          },
          didReceiveDatabaseUpdate: (DatabasePB database) {
            emit(state.copyWith(database: Some(database)));
          },
          didReceiveError: (FlowyError error) {
            emit(state.copyWith(noneOrError: Some(error)));
          },
        );
      },
    );
  }

  Future<void> _openDatabase(Emitter<CalendarState> emit) async {
    final result = await _databaseDataController.openDatabase();
    result.fold(
      (database) => emit(
        state.copyWith(loadingState: DatabaseLoadingState.finish(left(unit))),
      ),
      (err) => emit(
        state.copyWith(loadingState: DatabaseLoadingState.finish(right(err))),
      ),
    );
  }

  RowCache? getRowCache(String blockId) {
    return _databaseDataController.rowCache;
  }

  void _startListening() {
    _databaseDataController.addListener(
      onDatabaseChanged: (database) {
        if (!isClosed) return;

        add(CalendarEvent.didReceiveDatabaseUpdate(database));
      },
      onSettingsChanged: (CalendarSettingsPB settings) {
        if (isClosed) return;
        add(CalendarEvent.didReceiveCalendarSettings(settings));
      },
      onArrangeWithNewField: (field) {
        if (isClosed) return;
        _initializeEvents(field);
        // add(CalendarEvent.)
      },
      onError: (err) {
        Log.error(err);
      },
    );
  }

  void _initializeEvents(FieldPB dateField) {
    calendarEventsController.removeWhere((element) => true);

    const events = <CalendarEventData<DateCellData>>[];

    // final List<CalendarEventData<DateCellData>> events = rows.map((row) {
    // final event = CalendarEventData(
    //   title: "",
    //   date: row -> dateField -> value,
    //   event: row,
    // );

    // return event;
    // }).toList();

    calendarEventsController.addAll(events);
  }
}

@freezed
class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent.initial() = _InitialCalendar;
  const factory CalendarEvent.didReceiveCalendarSettings(
      CalendarSettingsPB settings) = _DidReceiveCalendarSettings;
  const factory CalendarEvent.didReceiveError(FlowyError error) =
      _DidReceiveError;
  const factory CalendarEvent.didReceiveDatabaseUpdate(DatabasePB database) =
      _DidReceiveDatabaseUpdate;
}

@freezed
class CalendarState with _$CalendarState {
  const factory CalendarState({
    required String databaseId,
    required Option<DatabasePB> database,
    required Option<FieldPB> dateField,
    required Option<List<RowInfo>> unscheduledRows,
    required Option<CalendarSettingsPB> settings,
    required DatabaseLoadingState loadingState,
    required Option<FlowyError> noneOrError,
  }) = _CalendarState;

  factory CalendarState.initial(String databaseId) => CalendarState(
        database: none(),
        databaseId: databaseId,
        dateField: none(),
        unscheduledRows: none(),
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

class DateCellData {
  final RowInfo rowInfo;
  DateCellData(this.rowInfo);
}
