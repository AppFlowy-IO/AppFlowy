import 'package:appflowy/features/shared_section/presentation/widgets/refresh_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../widget_test_wrapper.dart';

void main() {
  group('refresh_button.dart: ', () {
    testWidgets('shows refresh icon and triggers callback',
        (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        WidgetTestWrapper(
          child: RefreshSharedSectionButton(
            onTap: () => pressed = true,
          ),
        ),
      );
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });
  });
}
