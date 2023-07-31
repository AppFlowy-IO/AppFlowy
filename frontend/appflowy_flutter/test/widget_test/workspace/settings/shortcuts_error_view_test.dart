import 'package:appflowy/workspace/presentation/settings/widgets/settings_customize_shortcuts_view.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ShortcutsErrorView", () {
    testWidgets("displays correctly", (widgetTester) async {
      await widgetTester.pumpWidget(
        const MaterialApp(
          home: ShortcutsErrorView(
            errorMessage: 'Error occured',
          ),
        ),
      );

      expect(find.byType(FlowyText), findsOneWidget);
      expect(find.byType(FlowyIconButton), findsOneWidget);
    });
  });
}
