import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('board add row test', () {
    testWidgets('Add card from header', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.notifications);
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);

      // Defaults to enabled
      Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, true);

      // Disable
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, false);

      // Enable again
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, true);
    });
  });
}
