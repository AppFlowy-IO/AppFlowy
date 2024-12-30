import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_date_block.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/desktop_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../shared/util.dart';

void main() {
  setUp(() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('date or reminder block in document:', () {
    testWidgets("insert date with time block", (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: 'Date with time test',
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName(
        LocaleKeys.document_slashMenu_name_dateOrReminder.tr(),
      );

      final dateTimeSettings = DateTimeSettingsPB(
        dateFormat: UserDateFormatPB.Friendly,
        timeFormat: UserTimeFormatPB.TwentyFourHour,
      );
      final DateTime currentDateTime = DateTime.now();
      final String formattedDate =
          dateTimeSettings.dateFormat.formatDate(currentDateTime, false);

      // get current date in editor
      expect(find.byType(MentionDateBlock), findsOneWidget);
      expect(find.text('@$formattedDate'), findsOneWidget);

      // tap on date field
      await tester.tap(find.byType(MentionDateBlock));
      await tester.pumpAndSettle();

      // tap the toggle of include time
      await tester.tap(find.byType(Toggle));
      await tester.pumpAndSettle();

      // add time 11:12
      final textField = find
          .descendant(
            of: find.byType(DesktopAppFlowyDatePicker),
            matching: find.byType(TextField),
          )
          .last;
      await tester.pumpUntilFound(textField);
      await tester.enterText(textField, "11:12");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // we will get field with current date and 11:12 as time
      expect(find.byType(MentionDateBlock), findsOneWidget);
      expect(find.text('@$formattedDate 11:12'), findsOneWidget);
    });

    testWidgets("insert date with reminder block", (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: 'Date with reminder test',
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName(
        LocaleKeys.document_slashMenu_name_dateOrReminder.tr(),
      );

      final dateTimeSettings = DateTimeSettingsPB(
        dateFormat: UserDateFormatPB.Friendly,
        timeFormat: UserTimeFormatPB.TwentyFourHour,
      );
      final DateTime currentDateTime = DateTime.now();
      final String formattedDate =
          dateTimeSettings.dateFormat.formatDate(currentDateTime, false);

      // get current date in editor
      expect(find.byType(MentionDateBlock), findsOneWidget);
      expect(find.text('@$formattedDate'), findsOneWidget);

      // tap on date field
      await tester.tap(find.byType(MentionDateBlock));
      await tester.pumpAndSettle();

      // tap reminder and set reminder to 1 day before
      await tester.tap(find.text(LocaleKeys.datePicker_reminderLabel.tr()));
      await tester.pumpAndSettle();
      await tester.tap(
        find.textContaining(
          LocaleKeys.datePicker_reminderOptions_oneDayBefore.tr(),
        ),
      );

      await tester.editor.tapLineOfEditorAt(0);
      await tester.pumpAndSettle();

      // we will get field with current date reminder_clock.svg icon
      expect(find.byType(MentionDateBlock), findsOneWidget);
      expect(find.text('@$formattedDate'), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.reminder_clock_s), findsOneWidget);
    });

    testWidgets("copy, cut and paste a date mention", (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: 'copy, cut and paste a date mention',
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName(
        LocaleKeys.document_slashMenu_name_dateOrReminder.tr(),
      );

      final dateTimeSettings = DateTimeSettingsPB(
        dateFormat: UserDateFormatPB.Friendly,
        timeFormat: UserTimeFormatPB.TwentyFourHour,
      );
      final DateTime currentDateTime = DateTime.now();
      final String formattedDate =
          dateTimeSettings.dateFormat.formatDate(currentDateTime, false);

      // get current date in editor
      expect(find.byType(MentionDateBlock), findsOneWidget);
      expect(find.text('@$formattedDate'), findsOneWidget);

      // update selection and copy
      await tester.editor.updateSelection(
        Selection(
          start: Position(path: [0]),
          end: Position(path: [0], offset: 1),
        ),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyC,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      // update selection and paste
      await tester.editor.updateSelection(
        Selection.collapsed(Position(path: [0], offset: 1)),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MentionDateBlock), findsNWidgets(2));
      expect(find.text('@$formattedDate'), findsNWidgets(2));

      // update selection and cut
      await tester.editor.updateSelection(
        Selection(
          start: Position(path: [0], offset: 1),
          end: Position(path: [0], offset: 2),
        ),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyX,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MentionDateBlock), findsOneWidget);
      expect(find.text('@$formattedDate'), findsOneWidget);

      // update selection and paste
      await tester.editor.updateSelection(
        Selection.collapsed(Position(path: [0], offset: 1)),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MentionDateBlock), findsNWidgets(2));
      expect(find.text('@$formattedDate'), findsNWidgets(2));
    });

    testWidgets("copy, cut and paste a reminder mention", (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: 'copy, cut and paste a reminder mention',
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName(
        LocaleKeys.document_slashMenu_name_dateOrReminder.tr(),
      );

      // trigger popup
      await tester.tapButton(find.byType(MentionDateBlock));
      await tester.pumpAndSettle();

      // set date to be fifteenth of the next month
      await tester.tap(
        find.descendant(
          of: find.byType(DesktopAppFlowyDatePicker),
          matching: find.byFlowySvg(FlowySvgs.arrow_right_s),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(TableCalendar),
          matching: find.text(15.toString()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // add a reminder
      await tester.tap(find.byType(MentionDateBlock));
      await tester.pumpAndSettle();
      await tester.tap(find.text(LocaleKeys.datePicker_reminderLabel.tr()));
      await tester.pumpAndSettle();
      await tester.tap(
        find.textContaining(
          LocaleKeys.datePicker_reminderOptions_oneDayBefore.tr(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // verify
      final dateTimeSettings = DateTimeSettingsPB(
        dateFormat: UserDateFormatPB.Friendly,
        timeFormat: UserTimeFormatPB.TwentyFourHour,
      );
      final now = DateTime.now();
      final fifteenthOfNextMonth = DateTime(now.year, now.month + 1, 15);
      final formattedDate =
          dateTimeSettings.dateFormat.formatDate(fifteenthOfNextMonth, false);

      expect(find.byType(MentionDateBlock), findsOneWidget);
      expect(find.text('@$formattedDate'), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.reminder_clock_s), findsOneWidget);
      expect(getIt<ReminderBloc>().state.reminders.map((e) => e.id).length, 1);

      // update selection and copy
      await tester.editor.updateSelection(
        Selection(
          start: Position(path: [0]),
          end: Position(path: [0], offset: 1),
        ),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyC,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      // update selection and paste
      await tester.editor.updateSelection(
        Selection.collapsed(Position(path: [0], offset: 1)),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MentionDateBlock), findsNWidgets(2));
      expect(find.text('@$formattedDate'), findsNWidgets(2));
      expect(find.byFlowySvg(FlowySvgs.reminder_clock_s), findsNWidgets(2));
      expect(
        getIt<ReminderBloc>().state.reminders.map((e) => e.id).toSet().length,
        2,
      );

      // update selection and cut
      await tester.editor.updateSelection(
        Selection(
          start: Position(path: [0], offset: 1),
          end: Position(path: [0], offset: 2),
        ),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyX,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MentionDateBlock), findsOneWidget);
      expect(find.text('@$formattedDate'), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.reminder_clock_s), findsOneWidget);
      expect(getIt<ReminderBloc>().state.reminders.map((e) => e.id).length, 1);

      // update selection and paste
      await tester.editor.updateSelection(
        Selection.collapsed(Position(path: [0], offset: 1)),
      );
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyV,
        isControlPressed: Platform.isLinux || Platform.isWindows,
        isMetaPressed: Platform.isMacOS,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MentionDateBlock), findsNWidgets(2));
      expect(find.text('@$formattedDate'), findsNWidgets(2));
      expect(find.byType(MentionDateBlock), findsNWidgets(2));
      expect(find.text('@$formattedDate'), findsNWidgets(2));
      expect(find.byFlowySvg(FlowySvgs.reminder_clock_s), findsNWidgets(2));
      expect(
        getIt<ReminderBloc>().state.reminders.map((e) => e.id).toSet().length,
        2,
      );
    });

    testWidgets("delete, undo and redo a reminder mention", (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: 'delete, undo and redo a reminder mention',
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName(
        LocaleKeys.document_slashMenu_name_dateOrReminder.tr(),
      );

      // trigger popup
      await tester.tapButton(find.byType(MentionDateBlock));
      await tester.pumpAndSettle();

      // set date to be fifteenth of the next month
      await tester.tap(
        find.descendant(
          of: find.byType(DesktopAppFlowyDatePicker),
          matching: find.byFlowySvg(FlowySvgs.arrow_right_s),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(TableCalendar),
          matching: find.text(15.toString()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // add a reminder
      await tester.tap(find.byType(MentionDateBlock));
      await tester.pumpAndSettle();
      await tester.tap(find.text(LocaleKeys.datePicker_reminderLabel.tr()));
      await tester.pumpAndSettle();
      await tester.tap(
        find.textContaining(
          LocaleKeys.datePicker_reminderOptions_oneDayBefore.tr(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.simulateKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // verify
      final dateTimeSettings = DateTimeSettingsPB(
        dateFormat: UserDateFormatPB.Friendly,
        timeFormat: UserTimeFormatPB.TwentyFourHour,
      );
      final now = DateTime.now();
      final fifteenthOfNextMonth = DateTime(now.year, now.month + 1, 15);
      final formattedDate =
          dateTimeSettings.dateFormat.formatDate(fifteenthOfNextMonth, false);

      expect(find.byType(MentionDateBlock), findsOneWidget);
      expect(find.text('@$formattedDate'), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.reminder_clock_s), findsOneWidget);
      expect(getIt<ReminderBloc>().state.reminders.map((e) => e.id).length, 1);

      // update selection and backspace to delete the mention
      await tester.editor.updateSelection(
        Selection.collapsed(Position(path: [0], offset: 1)),
      );
      await tester.simulateKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      expect(find.byType(MentionDateBlock), findsNothing);
      expect(find.text('@$formattedDate'), findsNothing);
      expect(find.byFlowySvg(FlowySvgs.reminder_clock_s), findsNothing);
      expect(getIt<ReminderBloc>().state.reminders.isEmpty, isTrue);

      // undo
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isControlPressed: Platform.isWindows || Platform.isLinux,
        isMetaPressed: Platform.isMacOS,
      );

      expect(find.byType(MentionDateBlock), findsOneWidget);
      expect(find.text('@$formattedDate'), findsOneWidget);
      expect(find.byFlowySvg(FlowySvgs.reminder_clock_s), findsOneWidget);
      expect(getIt<ReminderBloc>().state.reminders.map((e) => e.id).length, 1);

      // redo
      await tester.simulateKeyEvent(
        LogicalKeyboardKey.keyZ,
        isControlPressed: Platform.isWindows || Platform.isLinux,
        isMetaPressed: Platform.isMacOS,
        isShiftPressed: true,
      );

      expect(find.byType(MentionDateBlock), findsNothing);
      expect(find.text('@$formattedDate'), findsNothing);
      expect(find.byFlowySvg(FlowySvgs.reminder_clock_s), findsNothing);
      expect(getIt<ReminderBloc>().state.reminders.isEmpty, isTrue);
    });
  });
}
