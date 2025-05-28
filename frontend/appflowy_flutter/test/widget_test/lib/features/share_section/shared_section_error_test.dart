import 'package:appflowy/features/shared_section/presentation/widgets/shared_section_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('shared_section_error.dart: ', () {
    testWidgets('shows error message', (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedSectionError(errorMessage: 'An error occurred'),
        ),
      );
      expect(find.text('An error occurred'), findsOneWidget);
      expect(find.byType(SharedSectionError), findsOneWidget);
    });
  });
}
