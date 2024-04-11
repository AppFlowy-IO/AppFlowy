import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_supabase_cloud.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('supabase auth', () {
    testWidgets('sign in with supabase', (tester) async {
      await tester.initializeAppFlowy(cloudType: AuthenticatorType.supabase);
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();
    });

    testWidgets('sign out with supabase', (tester) async {
      await tester.initializeAppFlowy(cloudType: AuthenticatorType.supabase);
      await tester.tapGoogleLoginInButton();

      // Open the setting page and sign out
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.user);
      await tester.tapButton(find.byType(SettingLogoutButton));

      tester.expectToSeeText(LocaleKeys.button_ok.tr());
      await tester.tapButtonWithName(LocaleKeys.button_ok.tr());

      // Go to the sign in page again
      await tester.pumpAndSettle(const Duration(seconds: 1));
      tester.expectToSeeGoogleLoginButton();
    });

    testWidgets('sign in as anonymous', (tester) async {
      await tester.initializeAppFlowy(cloudType: AuthenticatorType.supabase);
      await tester.tapSignInAsGuest();

      // should not see the sync setting page when sign in as anonymous
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.user);
      tester.expectToSeeGoogleLoginButton();
    });

    // testWidgets('enable encryption', (tester) async {
    //   await tester.initializeAppFlowy(cloudType: CloudType.supabase);
    //   await tester.tapGoogleLoginInButton();

    //   // Open the setting page and sign out
    //   await tester.openSettings();
    //   await tester.openSettingsPage(SettingsPage.cloud);

    //   // the switch should be off by default
    //   tester.assertEnableEncryptSwitchValue(false);
    //   await tester.toggleEnableEncrypt();

    //   // the switch should be on after toggling
    //   tester.assertEnableEncryptSwitchValue(true);

    //   // the switch can not be toggled back to off
    //   await tester.toggleEnableEncrypt();
    //   tester.assertEnableEncryptSwitchValue(true);
    // });

    testWidgets('enable sync', (tester) async {
      await tester.initializeAppFlowy(cloudType: AuthenticatorType.supabase);
      await tester.tapGoogleLoginInButton();

      // Open the setting page and sign out
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.cloud);

      // the switch should be on by default
      tester.assertSupabaseEnableSyncSwitchValue(true);
      await tester.toggleEnableSync(SupabaseEnableSync);

      // the switch should be off
      tester.assertSupabaseEnableSyncSwitchValue(false);

      // the switch should be on after toggling
      await tester.toggleEnableSync(SupabaseEnableSync);
      tester.assertSupabaseEnableSyncSwitchValue(true);
    });
  });
}
