import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/pages/account/account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('appflowy cloud', () {
    testWidgets('anon user -> sign in -> open imported space', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );

      await tester.tapContinousAnotherWay();
      await tester.tapAnonymousSignInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      const pageName = 'Test Document';
      await tester.createNewPageWithNameUnderParent(name: pageName);
      tester.expectToSeePageName(pageName);

      // rename the name of the anon user
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.account);
      await tester.pumpAndSettle();

      await tester.enterUserName('local_user');

      // Scroll to sign-in
      await tester.scrollUntilVisible(
        find.byType(AccountSignInOutSection),
        100,
        scrollable: find.findSettingsScrollable(),
      );

      await tester.tapButton(find.byType(AccountSignInOutSection));

      // sign up with Google
      await tester.tapGoogleLoginInButton();
      // await tester.pumpAndSettle(const Duration(seconds: 16));

      // open the imported space
      await tester.expectToSeeHomePage();
      await tester.clickSpaceHeader();

      // After import the anon user data, we will create a new space for it
      await tester.openSpace("Getting started");
      await tester.openPage(pageName);

      await tester.pumpAndSettle();
    });
  });
}
