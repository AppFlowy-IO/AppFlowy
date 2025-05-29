import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/access_level_list_widget.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('access_level_list_widget.dart: ', () {
    testWidgets('shows all access levels and highlights selected',
        (WidgetTester tester) async {
      // Track callback invocations
      ShareAccessLevel? selectedLevel;
      bool turnedIntoMember = false;
      bool removedAccess = false;

      await tester.pumpWidget(
        WidgetTestWrapper(
          child: AccessLevelListWidget(
            selectedAccessLevel: ShareAccessLevel.readAndWrite,
            supportedAccessLevels: ShareAccessLevel.values,
            callbacks: AccessLevelListCallbacks(
              onSelectAccessLevel: (level) => selectedLevel = level,
              onTurnIntoMember: () => turnedIntoMember = true,
              onRemoveAccess: () => removedAccess = true,
            ),
          ),
        ),
      );

      // Check all access level options are present
      expect(find.text(ShareAccessLevel.fullAccess.i18n), findsOneWidget);
      expect(find.text(ShareAccessLevel.readAndWrite.i18n), findsOneWidget);
      expect(find.text(ShareAccessLevel.readAndComment.i18n), findsOneWidget);
      expect(find.text(ShareAccessLevel.readOnly.i18n), findsOneWidget);

      // Check that the selected access level is visually marked
      final selectedTile = tester
          .widgetList<AFTextMenuItem>(find.byType(AFTextMenuItem))
          .where((item) => item.selected);
      expect(selectedTile.length, 1);
      expect(selectedTile.first.title, ShareAccessLevel.readAndWrite.i18n);

      // Tap on another access level
      await tester.tap(find.text(ShareAccessLevel.readOnly.i18n));
      await tester.pumpAndSettle();
      expect(selectedLevel, ShareAccessLevel.readOnly);

      // Tap on Turn into Member
      await tester.tap(find.text(LocaleKeys.shareTab_turnIntoMember.tr()));
      await tester.pumpAndSettle();
      expect(turnedIntoMember, isTrue);

      // Tap on Remove access
      await tester.tap(find.text(LocaleKeys.shareTab_removeAccess.tr()));
      await tester.pumpAndSettle();
      expect(removedAccess, isTrue);
    });
  });
}
