import 'package:appflowy/plugins/database/application/cell/bloc/date_cell_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time/time.dart';

import '../util.dart';

void main() {
  late AppFlowyGridTest cellTest;

  setUpAll(() async {
    cellTest = await AppFlowyGridTest.ensureInitialized();
  });

  group('date time cell bloc:', () {
    late GridTestContext context;
    late DateCellController cellController;

    setUp(() async {
      context = await cellTest.makeDefaultTestGrid();
      await FieldBackendService.createField(
        viewId: context.viewId,
        fieldType: FieldType.DateTime,
      );
      await gridResponseFuture();
      final fieldIndex = context.fieldController.fieldInfos
          .indexWhere((field) => field.fieldType == FieldType.DateTime);
      cellController = context.makeGridCellController(fieldIndex, 0).as();
    });

    test('select date', () async {
      final reminderBloc = ReminderBloc();
      final bloc = DateCellEditorBloc(
        cellController: cellController,
        reminderBloc: reminderBloc,
      );
      await gridResponseFuture();

      expect(bloc.state.dateTime, null);
      expect(bloc.state.endDateTime, null);
      expect(bloc.state.includeTime, false);
      expect(bloc.state.isRange, false);

      final now = DateTime.now();
      bloc.add(DateCellEditorEvent.updateDateTime(now));
      await gridResponseFuture();

      expect(bloc.state.dateTime!.isAtSameMinuteAs(now), true);
    });

    test('include time', () async {
      final reminderBloc = ReminderBloc();
      final bloc = DateCellEditorBloc(
        cellController: cellController,
        reminderBloc: reminderBloc,
      );
      await gridResponseFuture();

      final now = DateTime.now();
      bloc.add(DateCellEditorEvent.setIncludeTime(true, now, null));
      await gridResponseFuture();

      expect(bloc.state.includeTime, true);
      expect(bloc.state.dateTime!.isAtSameMinuteAs(now), true);
      expect(bloc.state.endDateTime, null);

      bloc.add(const DateCellEditorEvent.setIncludeTime(false, null, null));
      await gridResponseFuture();

      expect(bloc.state.includeTime, false);
      expect(bloc.state.dateTime!.isAtSameMinuteAs(now), true);
      expect(bloc.state.endDateTime, null);
    });

    test('end time basic', () async {
      final reminderBloc = ReminderBloc();
      final bloc = DateCellEditorBloc(
        cellController: cellController,
        reminderBloc: reminderBloc,
      );
      await gridResponseFuture();

      expect(bloc.state.isRange, false);
      expect(bloc.state.dateTime, null);
      expect(bloc.state.endDateTime, null);

      final now = DateTime.now();
      bloc.add(DateCellEditorEvent.updateDateTime(now));
      await gridResponseFuture();

      expect(bloc.state.isRange, false);
      expect(bloc.state.dateTime!.isAtSameMinuteAs(now), true);
      expect(bloc.state.endDateTime, null);

      bloc.add(const DateCellEditorEvent.setIsRange(true, null, null));
      await gridResponseFuture();

      expect(bloc.state.isRange, true);
      expect(bloc.state.dateTime!.isAtSameMinuteAs(now), true);
      expect(bloc.state.endDateTime!.isAtSameMinuteAs(now), true);

      bloc.add(const DateCellEditorEvent.setIsRange(false, null, null));
      await gridResponseFuture();

      expect(bloc.state.isRange, false);
      expect(bloc.state.dateTime!.isAtSameMinuteAs(now), true);
      expect(bloc.state.endDateTime, null);
    });

    test('end time from empty', () async {
      final reminderBloc = ReminderBloc();
      final bloc = DateCellEditorBloc(
        cellController: cellController,
        reminderBloc: reminderBloc,
      );
      await gridResponseFuture();

      expect(bloc.state.isRange, false);
      expect(bloc.state.dateTime, null);
      expect(bloc.state.endDateTime, null);

      final now = DateTime.now();
      bloc.add(DateCellEditorEvent.setIsRange(true, now, now));
      await gridResponseFuture();

      expect(bloc.state.isRange, true);
      expect(bloc.state.dateTime!.isAtSameDayAs(now), true);
      expect(bloc.state.endDateTime!.isAtSameDayAs(now), true);

      bloc.add(const DateCellEditorEvent.setIsRange(false, null, null));
      await gridResponseFuture();

      expect(bloc.state.isRange, false);
      expect(bloc.state.dateTime!.isAtSameDayAs(now), true);
      expect(bloc.state.endDateTime, null);
    });

    test('end time unexpected null', () async {
      final reminderBloc = ReminderBloc();
      final bloc = DateCellEditorBloc(
        cellController: cellController,
        reminderBloc: reminderBloc,
      );
      await gridResponseFuture();

      expect(bloc.state.isRange, false);
      expect(bloc.state.dateTime, null);
      expect(bloc.state.endDateTime, null);

      final now = DateTime.now();
      // pass in unexpected null as end date time
      bloc.add(DateCellEditorEvent.setIsRange(true, now, null));
      await gridResponseFuture();

      // no changes
      expect(bloc.state.isRange, false);
      expect(bloc.state.dateTime, null);
      expect(bloc.state.endDateTime, null);
    });

    test('end time unexpected end', () async {
      final reminderBloc = ReminderBloc();
      final bloc = DateCellEditorBloc(
        cellController: cellController,
        reminderBloc: reminderBloc,
      );
      await gridResponseFuture();

      expect(bloc.state.isRange, false);
      expect(bloc.state.dateTime, null);
      expect(bloc.state.endDateTime, null);

      final now = DateTime.now();
      bloc.add(DateCellEditorEvent.setIsRange(true, now, now));
      await gridResponseFuture();

      bloc.add(DateCellEditorEvent.setIsRange(false, now, now));
      await gridResponseFuture();

      // no change
      expect(bloc.state.isRange, true);
      expect(bloc.state.dateTime!.isAtSameDayAs(now), true);
      expect(bloc.state.endDateTime!.isAtSameDayAs(now), true);
    });

    test('clear date', () async {
      final reminderBloc = ReminderBloc();
      final bloc = DateCellEditorBloc(
        cellController: cellController,
        reminderBloc: reminderBloc,
      );
      await gridResponseFuture();

      final now = DateTime.now();
      bloc.add(DateCellEditorEvent.setIsRange(true, now, now));
      await gridResponseFuture();
      bloc.add(DateCellEditorEvent.setIncludeTime(true, now, now));
      await gridResponseFuture();

      expect(bloc.state.isRange, true);
      expect(bloc.state.includeTime, true);
      expect(bloc.state.dateTime!.isAtSameMinuteAs(now), true);
      expect(bloc.state.endDateTime!.isAtSameMinuteAs(now), true);

      bloc.add(const DateCellEditorEvent.clearDate());
      await gridResponseFuture();

      expect(bloc.state.dateTime, null);
      expect(bloc.state.endDateTime, null);
      expect(bloc.state.includeTime, false);
      expect(bloc.state.isRange, false);
    });

    test('set date format', () async {
      final reminderBloc = ReminderBloc();
      final bloc = DateCellEditorBloc(
        cellController: cellController,
        reminderBloc: reminderBloc,
      );
      await gridResponseFuture();

      expect(
        bloc.state.dateTypeOptionPB.dateFormat,
        DateFormatPB.Friendly,
      );
      expect(
        bloc.state.dateTypeOptionPB.timeFormat,
        TimeFormatPB.TwentyFourHour,
      );

      bloc.add(
        const DateCellEditorEvent.setDateFormat(DateFormatPB.ISO),
      );
      await gridResponseFuture();
      expect(
        bloc.state.dateTypeOptionPB.dateFormat,
        DateFormatPB.ISO,
      );

      bloc.add(
        const DateCellEditorEvent.setTimeFormat(TimeFormatPB.TwelveHour),
      );
      await gridResponseFuture();
      expect(
        bloc.state.dateTypeOptionPB.timeFormat,
        TimeFormatPB.TwelveHour,
      );
    });

    test('set reminder option', () async {
      final reminderBloc = ReminderBloc();
      final bloc = DateCellEditorBloc(
        cellController: cellController,
        reminderBloc: reminderBloc,
      );
      await gridResponseFuture();

      expect(reminderBloc.state.reminders.length, 0);

      final now = DateTime.now();
      final threeDaysFromToday = DateTime(now.year, now.month, now.day + 3);
      final fourDaysFromToday = DateTime(now.year, now.month, now.day + 4);
      final fiveDaysFromToday = DateTime(now.year, now.month, now.day + 5);

      bloc.add(DateCellEditorEvent.updateDateTime(threeDaysFromToday));
      await gridResponseFuture();

      bloc.add(
        const DateCellEditorEvent.setReminderOption(
          ReminderOption.onDayOfEvent,
        ),
      );
      await gridResponseFuture();

      expect(reminderBloc.state.reminders.length, 1);
      expect(
        reminderBloc.state.reminders.first.scheduledAt,
        Int64(
          threeDaysFromToday
                  .add(const Duration(hours: 9))
                  .millisecondsSinceEpoch ~/
              1000,
        ),
      );

      reminderBloc.add(const ReminderEvent.refresh());
      await gridResponseFuture();

      expect(reminderBloc.state.reminders.length, 1);
      expect(
        reminderBloc.state.reminders.first.scheduledAt,
        Int64(
          threeDaysFromToday
                  .add(const Duration(hours: 9))
                  .millisecondsSinceEpoch ~/
              1000,
        ),
      );

      bloc.add(DateCellEditorEvent.updateDateTime(fourDaysFromToday));
      await gridResponseFuture();
      expect(reminderBloc.state.reminders.length, 1);
      expect(
        reminderBloc.state.reminders.first.scheduledAt,
        Int64(
          fourDaysFromToday
                  .add(const Duration(hours: 9))
                  .millisecondsSinceEpoch ~/
              1000,
        ),
      );

      bloc.add(DateCellEditorEvent.updateDateTime(fiveDaysFromToday));
      await gridResponseFuture();
      reminderBloc.add(const ReminderEvent.refresh());
      await gridResponseFuture();
      expect(reminderBloc.state.reminders.length, 1);
      expect(
        reminderBloc.state.reminders.first.scheduledAt,
        Int64(
          fiveDaysFromToday
                  .add(const Duration(hours: 9))
                  .millisecondsSinceEpoch ~/
              1000,
        ),
      );

      bloc.add(
        const DateCellEditorEvent.setReminderOption(
          ReminderOption.twoDaysBefore,
        ),
      );
      await gridResponseFuture();
      expect(reminderBloc.state.reminders.length, 1);
      expect(
        reminderBloc.state.reminders.first.scheduledAt,
        Int64(
          threeDaysFromToday
                  .add(const Duration(hours: 9))
                  .millisecondsSinceEpoch ~/
              1000,
        ),
      );

      bloc.add(
        const DateCellEditorEvent.setReminderOption(ReminderOption.none),
      );
      await gridResponseFuture();
      expect(reminderBloc.state.reminders.length, 0);
      reminderBloc.add(const ReminderEvent.refresh());
      await gridResponseFuture();
      expect(reminderBloc.state.reminders.length, 0);
    });

    test('set reminder option from empty', () async {
      final reminderBloc = ReminderBloc();
      final bloc = DateCellEditorBloc(
        cellController: cellController,
        reminderBloc: reminderBloc,
      );
      await gridResponseFuture();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      bloc.add(
        const DateCellEditorEvent.setReminderOption(
          ReminderOption.onDayOfEvent,
        ),
      );
      await gridResponseFuture();

      expect(bloc.state.dateTime, today);
      expect(reminderBloc.state.reminders.length, 1);
      expect(
        reminderBloc.state.reminders.first.scheduledAt,
        Int64(
          today.add(const Duration(hours: 9)).millisecondsSinceEpoch ~/ 1000,
        ),
      );

      bloc.add(const DateCellEditorEvent.clearDate());
      await gridResponseFuture();
      expect(reminderBloc.state.reminders.length, 0);
    });
  });
}
