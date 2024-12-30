import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/auth_operation.dart';
import '../../shared/base.dart';
import '../../shared/expectation.dart';
import '../../shared/settings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Billing', () {
    testWidgets('Local auth cannot see plan+billing', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapSignInAsGuest();
      await tester.expectToSeeHomePageWithGetStartedPage();

      await tester.openSettings();
      await tester.pumpAndSettle();

      // We check that another settings page is present to ensure
      // it's not a fluke
      expect(
        find.text(
          LocaleKeys.settings_workspacePage_menuLabel.tr(),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          LocaleKeys.settings_planPage_menuLabel.tr(),
          skipOffstage: false,
        ),
        findsNothing,
      );

      expect(
        find.text(
          LocaleKeys.settings_billingPage_menuLabel.tr(),
          skipOffstage: false,
        ),
        findsNothing,
      );
    });
  });
}
