// ignore_for_file: unused_import

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:integration_test/integration_test.dart';
import '../util/mock/mock_file_picker.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('appflowy cloud auth', () {
    testWidgets('sign in', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloud,
      );
      await tester.tapGoogleLoginInButton();
      tester.expectToSeeHomePage();
    });

    testWidgets('sign out', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloud,
      );
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

    testWidgets('sign in as annoymous', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloud,
      );
      await tester.tapSignInAsGuest();

      // should not see the sync setting page when sign in as annoymous
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.user);
      tester.expectToSeeGoogleLoginButton();
    });

    testWidgets('enable sync', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloud,
      );

      await tester.tapGoogleLoginInButton();
      // Open the setting page and sign out
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.cloud);

      // the switch should be on by default
      tester.assertAppFlowyCloudEnableSyncSwitchValue(true);
      await tester.toggleEnableSync(AppFlowyCloudEnableSync);

      // the switch should be off
      tester.assertAppFlowyCloudEnableSyncSwitchValue(false);

      // the switch should be on after toggling
      await tester.toggleEnableSync(AppFlowyCloudEnableSync);
      tester.assertAppFlowyCloudEnableSyncSwitchValue(true);
    });

    // testWidgets('custom folder sign in', (tester) async {
    //   const userA = 'UserA';
    //   final userAEmail = "${uuid()}@appflowy.io";
    //   final initialPath = p.join(userA, appFlowyDataFolder);
    //   final context = await tester.initializeAppFlowy(
    //     cloudType: AuthenticatorType.appflowyCloud,
    //     pathExtension: initialPath,
    //   );
    //   getIt.registerFactory<AuthService>(
    //     () => AppFlowyCloudMockAuthService(
    //       email: userAEmail,
    //     ),
    //   );
    //   // remove the last extension
    //   final rootPath = context.applicationDataDirectory.replaceFirst(
    //     initialPath,
    //     '',
    //   );
    //   await tester.tapGoogleLoginInButton();

    //   // Open the setting page and sign out
    //   await tester.openSettings();
    //   await tester.openSettingsPage(SettingsPage.user);
    //   await tester.enterUserName(userA);

    //   await tester.openSettingsPage(SettingsPage.files);
    //   await tester.pumpAndSettle();

    //   // mock the file_picker result
    //   await mockGetDirectoryPath(
    //     p.join(rootPath, "random_folder"),
    //   );

    //   // after selecting the folder, an annoymous user should be signed in
    //   await tester.tapCustomLocationButton();
    //   tester.expectToSeeHomePage();
    //   await tester.pumpAndSettle();

    //   // Login as userA in custom folder
    //   await tester.openSettings();
    //   await tester.openSettingsPage(SettingsPage.user);
    //   await tester.tapGoogleLoginInButton();

    //   await tester.pumpAndSettle(const Duration(seconds: 1));
    //   tester.expectToSeeHomePage();
    //   // UserA should be displayed
    //   tester.expectToSeeUserName(userA);
    // });
  });
}
