import 'package:appflowy/features/shared_section/presentation/widgets/shared_section_loading.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('shared_section_loading.dart: ', () {
    testWidgets('shows loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: SharedSectionLoading(),
        ),
      );
      expect(find.byType(SharedSectionLoading), findsOneWidget);
    });
  });
}
