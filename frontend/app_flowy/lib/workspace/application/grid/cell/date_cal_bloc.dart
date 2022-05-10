import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Cell;
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';
import 'cell_service.dart';
import 'package:dartz/dartz.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart';
part 'date_cal_bloc.freezed.dart';

class DateCalBloc extends Bloc<DateCalEvent, DateCalState> {
  final GridDefaultCellContext cellContext;
  void Function()? _onCellChangedFn;

  DateCalBloc({required this.cellContext}) : super(DateCalState.initial(cellContext)) {
    on<DateCalEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) async {
            _startListening();
            await _loadDateTypeOption(emit);
          },
          selectDay: (_SelectDay value) {
            if (!isSameDay(state.selectedDay, value.day)) {
              _updateCellData(value.day);
              emit(state.copyWith(selectedDay: value.day));
            }
          },
          setCalFormat: (_CalendarFormat value) {
            emit(state.copyWith(format: value.format));
          },
          setFocusedDay: (_FocusedDay value) {
            emit(state.copyWith(focusedDay: value.day));
          },
          didReceiveCellUpdate: (_DidReceiveCellUpdate value) {},
          setIncludeTime: (_IncludeTime value) async {
            await _updateTypeOption(emit, includeTime: value.includeTime);
          },
          setDateFormat: (_DateFormat value) async {
            await _updateTypeOption(emit, dateFormat: value.dateFormat);
          },
          setTimeFormat: (_TimeFormat value) async {
            await _updateTypeOption(emit, timeFormat: value.timeFormat);
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellContext.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    cellContext.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellContext.startListening(
      onCellChanged: ((cell) {
        if (!isClosed) {
          add(DateCalEvent.didReceiveCellUpdate(cell));
        }
      }),
    );
  }

  Future<void> _loadDateTypeOption(Emitter<DateCalState> emit) async {
    final result = await cellContext.getTypeOptionData();
    result.fold(
      (data) {
        final typeOptionData = DateTypeOption.fromBuffer(data);

        DateTime? selectedDay;
        final cellData = cellContext.getCellData()?.data;

        if (cellData != null) {
          final timestamp = $fixnum.Int64.parseInt(cellData).toInt();
          selectedDay = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }

        emit(state.copyWith(
          dateTypeOption: some(typeOptionData),
          selectedDay: selectedDay,
        ));
      },
      (err) => Log.error(err),
    );
  }

  void _updateCellData(DateTime day) {
    final data = day.millisecondsSinceEpoch ~/ 1000;
    cellContext.saveCellData(data.toString());
  }

  Future<void>? _updateTypeOption(
    Emitter<DateCalState> emit, {
    DateFormat? dateFormat,
    TimeFormat? timeFormat,
    bool? includeTime,
  }) async {
    final newDateTypeOption = state.dateTypeOption.fold(() => null, (dateTypeOption) {
      dateTypeOption.freeze();
      return dateTypeOption.rebuild((typeOption) {
        if (dateFormat != null) {
          typeOption.dateFormat = dateFormat;
        }

        if (timeFormat != null) {
          typeOption.timeFormat = timeFormat;
        }

        if (includeTime != null) {
          typeOption.includeTime = includeTime;
        }
      });
    });

    if (newDateTypeOption != null) {
      final result = await FieldService.updateFieldTypeOption(
        gridId: cellContext.gridId,
        fieldId: cellContext.field.id,
        typeOptionData: newDateTypeOption.writeToBuffer(),
      );

      result.fold(
        (l) => emit(state.copyWith(dateTypeOption: Some(newDateTypeOption))),
        (err) => Log.error(err),
      );
    }
  }
}

@freezed
class DateCalEvent with _$DateCalEvent {
  const factory DateCalEvent.initial() = _Initial;
  const factory DateCalEvent.selectDay(DateTime day) = _SelectDay;
  const factory DateCalEvent.setCalFormat(CalendarFormat format) = _CalendarFormat;
  const factory DateCalEvent.setFocusedDay(DateTime day) = _FocusedDay;
  const factory DateCalEvent.setTimeFormat(TimeFormat timeFormat) = _TimeFormat;
  const factory DateCalEvent.setDateFormat(DateFormat dateFormat) = _DateFormat;
  const factory DateCalEvent.setIncludeTime(bool includeTime) = _IncludeTime;
  const factory DateCalEvent.didReceiveCellUpdate(Cell cell) = _DidReceiveCellUpdate;
}

@freezed
class DateCalState with _$DateCalState {
  const factory DateCalState({
    required Option<DateTypeOption> dateTypeOption,
    required CalendarFormat format,
    required DateTime focusedDay,
    required Option<String> time,
    DateTime? selectedDay,
  }) = _DateCalState;

  factory DateCalState.initial(GridCellContext context) => DateCalState(
        dateTypeOption: none(),
        format: CalendarFormat.month,
        focusedDay: DateTime.now(),
        time: none(),
      );
}
