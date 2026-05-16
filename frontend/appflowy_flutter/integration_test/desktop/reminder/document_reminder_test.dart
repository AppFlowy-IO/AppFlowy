import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/user/application/user_settings_service.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_item.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/base.dart';
import '../../shared/common_operations.dart';
import '../../shared/document_test_operations.dart';
import '../../shared/expectation.dart';
import '../../shared/keyboard.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Reminder in Document', () {
    testWidgets('Add reminder for tomorrow, and include time', (tester) async {
      const time = "23:59";

      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      final dateTimeSettings =
          await UserSettingsBackendService().getDateTimeSettings();

      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.getCurrentEditorState().insertNewLine();

      await tester.pumpAndSettle();

      // Trigger inline action menu and type 'remind tomorrow'
      final tomorrow = await _insertReminderTomorrow(tester);

      Node node = tester.editor.getCurrentEditorState().getNodeAtPath([1])!;
      Map<String, dynamic> mentionAttr =
          node.delta!.first.attributes![MentionBlockKeys.mention];

      expect(node.type, 'paragraph');
      expect(mentionAttr['type'], MentionType.date.name);
      expect(mentionAttr['date'], tomorrow.toIso8601String());

      await tester.tap(
        find.text(dateTimeSettings.dateFormat.formatDate(tomorrow, false)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Toggle));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(FlowyTextField), time);

      // Leave text field to submit
      await tester.tap(find.text(LocaleKeys.grid_field_includeTime.tr()));
      await tester.pumpAndSettle();

      node = tester.editor.getCurrentEditorState().getNodeAtPath([1])!;
      mentionAttr = node.delta!.first.attributes![MentionBlockKeys.mention];

      final tomorrowWithTime =
          _dateWithTime(dateTimeSettings.timeFormat, tomorrow, time);

      expect(node.type, 'paragraph');
      expect(mentionAttr['type'], MentionType.date.name);
      expect(mentionAttr['date'], tomorrowWithTime.toIso8601String());
    });

    testWidgets('Add reminder for tomorrow, and navigate to it',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.getCurrentEditorState().insertNewLine();

      await tester.pumpAndSettle();

      // Trigger inline action menu and type 'remind tomorrow'
      final tomorrow = await _insertReminderTomorrow(tester);

      final Node node =
          tester.editor.getCurrentEditorState().getNodeAtPath([1])!;
      final Map<String, dynamic> mentionAttr =
          node.delta!.first.attributes![MentionBlockKeys.mention];

      expect(node.type, 'paragraph');
      expect(mentionAttr['type'], MentionType.date.name);
      expect(mentionAttr['date'], tomorrow.toIso8601String());

      // Create and Navigate to a new document
      await tester.createNewPageWithNameUnderParent();
      await tester.pumpAndSettle();

      // Open "Upcoming" in Notification hub
      await tester.openNotificationHub(tabIndex: 1);

      // Expect 1 notification
      tester.expectNotificationItems(1);

      // Tap on the notification
      await tester.tap(find.byType(NotificationItem));
      await tester.pumpAndSettle();

      // Expect node at path 1 to be the date/reminder
      expect(
        tester.editor
            .getCurrentEditorState()
            .getNodeAtPath([1])
            ?.delta
            ?.first
            .attributes?[MentionBlockKeys.mention]['type'],
        MentionType.date.name,
      );
    });
  });
}

Future<DateTime> _insertReminderTomorrow(WidgetTester tester) async {
  await tester.editor.showAtMenu();

  await FlowyTestKeyboard.simulateKeyDownEvent(
    [
      LogicalKeyboardKey.keyR,
      LogicalKeyboardKey.keyE,
      LogicalKeyboardKey.keyM,
      LogicalKeyboardKey.keyI,
      LogicalKeyboardKey.keyN,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.keyT,
      LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyM,
      LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyR,
      LogicalKeyboardKey.keyR,
      LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyW,
    ],
    tester: tester,
  );

  await FlowyTestKeyboard.simulateKeyDownEvent(
    [LogicalKeyboardKey.enter],
    tester: tester,
  );

  return DateTime.now().add(const Duration(days: 1)).withoutTime;
}

DateTime _dateWithTime(UserTimeFormatPB format, DateTime date, String time) {
  final t = format == UserTimeFormatPB.TwelveHour
      ? DateFormat.jm().parse(time)
      : DateFormat.Hm().parse(time);

  return DateTime.parse(
    '${date.year}${_padZeroLeft(date.month)}${_padZeroLeft(date.day)} ${_padZeroLeft(t.hour)}:${_padZeroLeft(t.minute)}',
  );
}

String _padZeroLeft(int a) => a.toString().padLeft(2, '0');
