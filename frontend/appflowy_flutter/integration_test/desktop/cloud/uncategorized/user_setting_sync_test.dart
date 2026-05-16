import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/pages/account/account_user_profile.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final email = '${uuid()}@appflowy.io';
  const name = 'nathan';

  group('appflowy cloud setting', () {
    testWidgets('sync user name and icon to server', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
        email: email,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.account);

      await tester.enterUserName(name);
      await tester.pumpAndSettle(const Duration(seconds: 6));
      await tester.logout();

      await tester.pumpAndSettle(const Duration(seconds: 2));
    });
  });
  testWidgets('get user icon and name from server', (tester) async {
    await tester.initializeAppFlowy(
      cloudType: AuthenticatorType.appflowyCloudSelfHost,
      email: email,
    );
    await tester.tapGoogleLoginInButton();
    await tester.expectToSeeHomePageWithGetStartedPage();
    await tester.pumpAndSettle();

    await tester.openSettings();
    await tester.openSettingsPage(SettingsPage.account);

    // Verify name
    final profileSetting =
        tester.widget(find.byType(AccountUserProfile)) as AccountUserProfile;

    expect(profileSetting.name, name);
  });
}
