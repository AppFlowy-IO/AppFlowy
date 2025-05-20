import 'package:appflowy/features/shared_section/presentation/widgets/shared_section_header.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('shared_section_header.dart: ', () {
    testWidgets('shows header title', (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: const SharedSectionHeader(),
        ),
      );
      expect(find.text('Shared'), findsOneWidget);
      expect(find.byType(SharedSectionHeader), findsOneWidget);
    });
  });
}
