import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_date_block.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  setUp(() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('date or reminder block in document', () {
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
      final currentTime = DateFormat('HH:mm').format(DateTime.now());
      final textField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.controller!.text == currentTime,
      );
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
  });
}
