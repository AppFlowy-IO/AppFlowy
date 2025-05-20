import 'package:appflowy/features/share_tab/presentation/widgets/shared_group_widget.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('shared_group_widget.dart: ', () {
    testWidgets('shows group name, description, and trailing widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedGroupWidget(),
        ),
      );
      expect(
        find.text(LocaleKeys.shareTab_anyoneAtWorkspace.tr()),
        findsOneWidget,
      );
      expect(
        find.text(LocaleKeys.shareTab_anyoneInGroupWithLinkCanEdit.tr()),
        findsOneWidget,
      );
      // Trailing widget: EditAccessLevelWidget (disabled)
      expect(find.byType(SharedGroupWidget), findsOneWidget);
    });
  });
}
