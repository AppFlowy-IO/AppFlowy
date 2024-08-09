import 'package:appflowy/plugins/database/widgets/cell/desktop_grid/desktop_grid_time_cell.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/time.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/time_cell_editor.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/start_text_field.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../shared/database_test_op.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Time Field', () {
    testWidgets('time plain time', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      await tester.createField(FieldType.Time, FieldType.Time.name);

      await tester.editCell(
        rowIndex: 0,
        fieldType: FieldType.Time,
        input: '142',
      );
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.Time,
        content: '2h 22m',
      );

      await tester.editCell(
        rowIndex: 1,
        fieldType: FieldType.Time,
        input: '31m',
      );
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      tester.assertCellContent(
        rowIndex: 1,
        fieldType: FieldType.Time,
        content: '31m',
      );

      await tester.editCell(
        rowIndex: 2,
        fieldType: FieldType.Time,
        input: '32h 31m',
      );
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      tester.assertCellContent(
        rowIndex: 2,
        fieldType: FieldType.Time,
        content: '32h 31m',
      );
    });

    testWidgets('change time precision option to seconds', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      await tester.createField(FieldType.Time, FieldType.Time.name);

      await tester.tapGridFieldWithName(FieldType.Time.name);
      await tester.tapEditFieldButton();
      await tester.changeTimePrecision(TimePrecisionPB.Seconds);
      await tester.dismissFieldEditor();

      await tester.editCell(
        rowIndex: 0,
        fieldType: FieldType.Time,
        input: '142',
      );
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.Time,
        content: '2m 22s',
      );

      await tester.editCell(
        rowIndex: 1,
        fieldType: FieldType.Time,
        input: '31m',
      );
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      tester.assertCellContent(
        rowIndex: 1,
        fieldType: FieldType.Time,
        content: '31m 0s',
      );

      await tester.editCell(
        rowIndex: 2,
        fieldType: FieldType.Time,
        input: '32h 31s',
      );
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      tester.assertCellContent(
        rowIndex: 2,
        fieldType: FieldType.Time,
        content: '32h 0m 31s',
      );
    });

    testWidgets('stopwatch time-type option add/remove time track',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      await tester.createField(FieldType.Time, FieldType.Time.name);

      await tester.tapGridFieldWithName(FieldType.Time.name);
      await tester.tapEditFieldButton();
      await tester.changeTimeType(TimeTypePB.Stopwatch);
      await tester.dismissFieldEditor();

      await tester.tapCellInGrid(rowIndex: 0, fieldType: FieldType.Time);
      expect(find.byType(TimeCellEditor), findsOne);
      expect(
        find.findTextInFlowyText(LocaleKeys.grid_field_timeTimerStartFrom.tr()),
        findsNothing,
      );
      expect(find.byType(TimeTrack), findsNothing);
      expect(find.byType(TimeTrackInput), findsOne);

      // Add time track
      await tester.tapButton(
        find.byWidgetPredicate(
          (widget) =>
              widget is FlowyTextField &&
              widget.hintText == LocaleKeys.grid_field_timeDateHintText.tr(),
        ),
      );
      expect(find.byType(AppFlowyDatePicker), findsOne);
      await tester.enterText(find.byType(StartTextField), '11:00');
      await tester.selectLastDateInPicker();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is FlowyTextField &&
              widget.hintText ==
                  LocaleKeys.grid_field_timeDurationHintText.tr(),
        ),
        '31m',
      );

      await tester
          .tapButtonWithName(LocaleKeys.grid_field_timeTimeTrackAddNew.tr());

      expect(find.byType(TimeTrack), findsOne);
      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.Time,
        content: '31m',
      );

      // Remove time track
      await tester.tapButtonWithFlowySvgData(FlowySvgs.trash_s);
      expect(find.byType(TimeTrack), findsNothing);
      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.Time,
        content: '',
      );
    });

    testWidgets('timer time-type add/remove time track', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      await tester.createField(FieldType.Time, FieldType.Time.name);

      await tester.tapGridFieldWithName(FieldType.Time.name);
      await tester.tapEditFieldButton();
      await tester.changeTimeType(TimeTypePB.Timer);
      await tester.dismissFieldEditor();

      await tester.tapCellInGrid(rowIndex: 0, fieldType: FieldType.Time);
      expect(find.byType(TimeCellEditor), findsOneWidget);
      expect(find.byType(TimeTrack), findsNothing);
      expect(find.byType(TimeTrackInput), findsOne);

      // Set timer start
      final timerStartFrom = find.byWidgetPredicate(
        (widget) =>
            widget is FlowyTextField &&
            widget.hintText ==
                LocaleKeys.grid_field_timeTimerStartFromHintText.tr(),
      );
      expect(timerStartFrom, findsOne);
      await tester.enterText(timerStartFrom, '74m');

      // Add time track
      await tester.tapButton(
        find.byWidgetPredicate(
          (widget) =>
              widget is FlowyTextField &&
              widget.hintText == LocaleKeys.grid_field_timeDateHintText.tr(),
        ),
      );
      expect(find.byType(AppFlowyDatePicker), findsOne);
      await tester.enterText(find.byType(StartTextField), '11:00');
      await tester.selectLastDateInPicker();

      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is FlowyTextField &&
              widget.hintText ==
                  LocaleKeys.grid_field_timeDurationHintText.tr(),
        ),
        '31m',
      );

      await tester
          .tapButtonWithName(LocaleKeys.grid_field_timeTimeTrackAddNew.tr());

      expect(find.byType(TimeTrack), findsOne);
      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.Time,
        content: '43m',
      );

      // Remove time track
      await tester.tapButtonWithFlowySvgData(FlowySvgs.trash_s);
      expect(find.byType(TimeTrack), findsNothing);
      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.Time,
        content: '1h 14m',
      );
    });

    testWidgets('start/stop tracking stopwatch', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);
      await tester.createField(FieldType.Time, FieldType.Time.name);

      await tester.tapGridFieldWithName(FieldType.Time.name);
      await tester.tapEditFieldButton();
      await tester.changeTimePrecision(TimePrecisionPB.Seconds);
      await tester.changeTimeType(TimeTypePB.Stopwatch);
      await tester.dismissFieldEditor();

      await tester.hoverOnWidget(tester.cellFinder(0, FieldType.Time));
      expect(find.byType(TimeTrackButton), findsOne);
      expect(find.byIcon(Icons.play_arrow), findsOne);
      tester.assertCellContent(
        rowIndex: 0,
        fieldType: FieldType.Time,
        content: '',
      );

      // Start tracking
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.pause), findsOne);

      final EditableTimeCellState state =
          tester.state(tester.cellFinder(0, FieldType.Time));
      final time = state.cellBloc.cellController.getCellData()!.time.toInt();
      expect(time >= 1, true);
      expect(state.cellBloc.state.isTracking, true);

      // Pause tracking
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(state.cellBloc.state.isTracking, false);
    });
  });
}
