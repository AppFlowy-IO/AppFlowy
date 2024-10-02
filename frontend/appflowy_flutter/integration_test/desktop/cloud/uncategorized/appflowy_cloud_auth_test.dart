// ignore_for_file: unused_import

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/pages/account/account.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_account_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../../../shared/mock/mock_file_picker.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('appflowy cloud auth', () {
    testWidgets('sign in', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();
    });

    testWidgets('sign out', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();

      // Open the setting page and sign out
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.account);

      // Scroll to sign-out
      await tester.scrollUntilVisible(
        find.byType(AccountSignInOutButton),
        100,
        scrollable: find.findSettingsScrollable(),
      );
      await tester.tapButton(find.byType(AccountSignInOutButton));

      tester.expectToSeeText(LocaleKeys.button_ok.tr());
      await tester.tapButtonWithName(LocaleKeys.button_ok.tr());

      // Go to the sign in page again
      await tester.pumpAndSettle(const Duration(seconds: 5));
      tester.expectToSeeGoogleLoginButton();
    });

    testWidgets('sign in as anonymous', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapSignInAsGuest();

      // should not see the sync setting page when sign in as anonymous
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.account);

      // Scroll to sign-in
      await tester.scrollUntilVisible(
        find.byType(AccountSignInOutButton),
        100,
        scrollable: find.findSettingsScrollable(),
      );
      await tester.tapButton(find.byType(AccountSignInOutButton));

      tester.expectToSeeGoogleLoginButton();
    });

    testWidgets('enable sync', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );

      await tester.tapGoogleLoginInButton();
      // Open the setting page and sign out
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.cloud);
      await tester.pumpAndSettle();

      // the switch should be on by default
      tester.assertAppFlowyCloudEnableSyncSwitchValue(true);
      await tester.toggleEnableSync(AppFlowyCloudEnableSync);
      // wait for the switch animation
      await tester.wait(250);

      // the switch should be off
      tester.assertAppFlowyCloudEnableSyncSwitchValue(false);

      // the switch should be on after toggling
      await tester.toggleEnableSync(AppFlowyCloudEnableSync);
      tester.assertAppFlowyCloudEnableSyncSwitchValue(true);
      await tester.wait(250);
    });
  });
}
