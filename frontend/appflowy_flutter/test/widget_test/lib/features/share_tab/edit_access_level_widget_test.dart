import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/access_level_list_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/edit_access_level_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('edit_access_level_widget.dart: ', () {
    testWidgets('shows selected access level and opens popover',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: EditAccessLevelWidget(
            selectedAccessLevel: ShareAccessLevel.readOnly,
            supportedAccessLevels: ShareAccessLevel.values,
            callbacks: AccessLevelListCallbacks(
              onSelectAccessLevel: (level) {},
              onTurnIntoMember: () {},
              onRemoveAccess: () {},
            ),
          ),
        ),
      );
      // Check selected access level is shown
      expect(find.text(ShareAccessLevel.readOnly.i18n), findsOneWidget);
      // Tap to open popover
      await tester.tap(find.text(ShareAccessLevel.readOnly.i18n));
      await tester.pumpAndSettle();
    });
  });
}
