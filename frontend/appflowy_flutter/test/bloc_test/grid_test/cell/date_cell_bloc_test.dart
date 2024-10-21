import 'package:appflowy/plugins/database/application/cell/bloc/date_cell_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
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
      final expected = DateTime(now.year, now.month, now.day);
      bloc.add(const DateCellEditorEvent.setIncludeTime(true));
      await gridResponseFuture();

      expect(bloc.state.includeTime, true);
      expect(bloc.state.dateTime!.isAtSameMinuteAs(expected), true);
      expect(bloc.state.endDateTime, null);

      bloc.add(const DateCellEditorEvent.setIncludeTime(false));
      await gridResponseFuture();

      expect(bloc.state.includeTime, false);
      expect(bloc.state.dateTime!.isAtSameMinuteAs(expected), true);
      expect(bloc.state.endDateTime, null);
    });

    test('end time', () async {
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
      final expected = DateTime(now.year, now.month, now.day);
      bloc.add(const DateCellEditorEvent.setIsRange(true));
      await gridResponseFuture();

      expect(bloc.state.isRange, true);
      expect(bloc.state.dateTime!.isAtSameMinuteAs(expected), true);
      expect(bloc.state.endDateTime!.isAtSameMinuteAs(expected), true);

      bloc.add(const DateCellEditorEvent.setIsRange(false));
      await gridResponseFuture();

      expect(bloc.state.isRange, false);
      expect(bloc.state.dateTime!.isAtSameMinuteAs(expected), true);
      expect(bloc.state.endDateTime, null);
    });

    test('clear date', () async {
      final reminderBloc = ReminderBloc();
      final bloc = DateCellEditorBloc(
        cellController: cellController,
        reminderBloc: reminderBloc,
      );
      await gridResponseFuture();

      final now = DateTime.now();
      final expected = DateTime(now.year, now.month, now.day);
      bloc.add(const DateCellEditorEvent.setIsRange(true));
      await gridResponseFuture();
      bloc.add(const DateCellEditorEvent.setIncludeTime(true));
      await gridResponseFuture();

      expect(bloc.state.isRange, true);
      expect(bloc.state.includeTime, true);
      expect(bloc.state.dateTime!.isAtSameMinuteAs(expected), true);
      expect(bloc.state.endDateTime!.isAtSameMinuteAs(expected), true);

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
  });
}
