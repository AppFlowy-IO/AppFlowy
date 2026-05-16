import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('notification test', () {
    testWidgets('enable notification', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.notifications);
      await tester.pumpAndSettle();

      final toggleFinder = find.byType(Toggle).first;

      // Defaults to enabled
      Toggle toggleWidget = tester.widget(toggleFinder);
      expect(toggleWidget.value, true);

      // Disable
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      toggleWidget = tester.widget(toggleFinder);
      expect(toggleWidget.value, false);

      // Enable again
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      toggleWidget = tester.widget(toggleFinder);
      expect(toggleWidget.value, true);
    });
  });
}
