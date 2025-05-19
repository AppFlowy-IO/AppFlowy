import 'package:appflowy/features/share_tab/presentation/widgets/general_access_section.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('general_access_section.dart: ', () {
    testWidgets('shows section title and SharedGroupWidget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: GeneralAccessSection(),
        ),
      );
      expect(find.text('General access'), findsOneWidget);
      expect(find.byType(GeneralAccessSection), findsOneWidget);
    });
  });
}
