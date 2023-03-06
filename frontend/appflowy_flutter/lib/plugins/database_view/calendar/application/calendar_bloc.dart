import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
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
  final EventController calendarEventsController = EventController();

  FieldController get fieldController => _databaseController.fieldController;
  String get viewId => _databaseController.viewId;

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
          },
          didReceiveCalendarSettings: (CalendarLayoutSettingsPB settings) {
            emit(state.copyWith(settings: Some(settings)));
          },
          didReceiveDatabaseUpdate: (DatabasePB database) {
            emit(state.copyWith(database: Some(database)));
          },
          didReceiveError: (FlowyError error) {
            emit(state.copyWith(noneOrError: Some(error)));
          },
          didReceiveFields: (FieldInfo primaryField, FieldInfo dateField) {
            emit(state.copyWith(
              dateField: Some(dateField),
              primaryField: Some(primaryField),
            ));
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

  RowCache? getRowCache(String blockId) {
    return _databaseController.rowCache;
  }

  void _startListening() {
    final onDatabaseChanged = DatabaseCallbacks(
      onDatabaseChanged: (database) {
        if (isClosed) return;
      },
      onRowsChanged: (rowInfos, reason) {
        if (isClosed) return;
        _updateCalendarEvents();
      },
      onFieldsChanged: (fieldInfos) {
        if (isClosed) return;
        _updateDateField();
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
      _updateDateField();
    }
  }

  void _updateDateField() {
    if (fieldController.fieldInfos.isEmpty) return;
    if (state.settings.isNone()) return;

    // Use the primary field's content as the title in calendar
    final primaryFieldIndex = fieldController.fieldInfos
        .indexWhere((element) => element.field.isPrimary);

    if (primaryFieldIndex != -1) {
      state.settings.fold(() => null, (settings) {
        final dateFieldIndex = fieldController.fieldInfos.indexWhere(
            (element) => element.field.id == settings.layoutFieldId);

        if (dateFieldIndex != -1) {
          add(CalendarEvent.didReceiveFields(
            fieldController.fieldInfos[primaryFieldIndex],
            fieldController.fieldInfos[dateFieldIndex],
          ));
          _updateCalendarEvents();
        }
      });
    }
  }

  void _updateCalendarEvents() {
    if (state.dateField.isNone()) return;
    if (_databaseController.rowInfos.isEmpty) return;
    calendarEventsController.removeWhere((element) => true);

    // final List<CalendarEventData<CalendarData>> events =
    //     _databaseController.rowInfos.map((rowInfo) {
    //   // final event = CalendarEventData(
    //   //   title: rowInfo,
    //   //   date: row -> dateField -> value,
    //   //   event: row,
    //   // );

    //   // return event;
    // }).toList();

    // calendarEventsController.addAll(events);
  }
}

@freezed
class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent.initial() = _InitialCalendar;
  const factory CalendarEvent.didReceiveFields(
      FieldInfo primaryField, FieldInfo dateFieldInfo) = _DidReceiveFields;
  const factory CalendarEvent.didReceiveCalendarSettings(
      CalendarLayoutSettingsPB settings) = _DidReceiveCalendarSettings;
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
    required Option<FieldInfo> dateField,
    required Option<FieldInfo> primaryField,
    required Option<List<RowInfo>> unscheduledRows,
    required Option<CalendarLayoutSettingsPB> settings,
    required DatabaseLoadingState loadingState,
    required Option<FlowyError> noneOrError,
  }) = _CalendarState;

  factory CalendarState.initial(String databaseId) => CalendarState(
        database: none(),
        databaseId: databaseId,
        dateField: none(),
        primaryField: none(),
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

class CalendarData {
  final RowInfo rowInfo;
  CalendarData(this.rowInfo);
}
