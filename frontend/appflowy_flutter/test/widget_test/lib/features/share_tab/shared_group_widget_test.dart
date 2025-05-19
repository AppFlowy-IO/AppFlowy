import 'package:appflowy/features/share_tab/presentation/widgets/shared_group_widget.dart';
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
      expect(find.text('Anyone at AppFlowy'), findsOneWidget);
      expect(
        find.text('Anyone in this group with the link can edit'),
        findsOneWidget,
      );
      // Trailing widget: EditAccessLevelWidget (disabled)
      expect(find.byType(SharedGroupWidget), findsOneWidget);
    });
  });
}
