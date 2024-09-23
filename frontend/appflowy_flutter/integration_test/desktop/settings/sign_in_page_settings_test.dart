import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/desktop_sign_in_screen.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder findServerType(AuthenticatorType type) {
    return find
        .descendant(
          of: find.byType(SettingsServerDropdownMenu),
          matching: find.findTextInFlowyText(
            type.label,
          ),
        )
        .last;
  }

  group('sign-in page settings: ', () {
    testWidgets('change server type', (tester) async {
      await tester.initializeAppFlowy();

      // reset the app to the default state
      await useAppFlowyBetaCloudWithURL(
        kAppflowyCloudUrl,
        AuthenticatorType.appflowyCloud,
      );

      // open the settings page
      final settingsButton = find.byType(DesktopSignInSettingsButton);
      await tester.tapButton(settingsButton);

      expect(find.byType(SimpleSettingsDialog), findsOneWidget);

      // the default type should be appflowy cloud
      final appflowyCloudType = findServerType(AuthenticatorType.appflowyCloud);
      expect(appflowyCloudType, findsOneWidget);

      // change the server type to self-host
      await tester.tapButton(appflowyCloudType);
      final selfhostedButton = findServerType(
        AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapButton(selfhostedButton);

      // update server url
      const serverUrl = 'https://test.appflowy.cloud';
      await tester.enterText(
        find.byKey(kSelfHostedTextInputFieldKey),
        serverUrl,
      );
      await tester.pumpAndSettle();
      await tester.tapButton(
        find.findTextInFlowyText(LocaleKeys.button_save.tr()),
      );

      // wait the app to restart
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      // open settings page to check the result
      await tester.tapButton(settingsButton);

      // check the server type
      expect(
        findServerType(AuthenticatorType.appflowyCloudSelfHost),
        findsOneWidget,
      );
      // check the server url
      expect(
        find.text(serverUrl),
        findsOneWidget,
      );

      // reset to appflowy cloud
      await tester.tapButton(
        findServerType(AuthenticatorType.appflowyCloudSelfHost),
      );
      // change the server type to appflowy cloud
      await tester.tapButton(
        findServerType(AuthenticatorType.appflowyCloud),
      );

      // wait the app to restart
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      // check the server type
      await tester.tapButton(settingsButton);
      expect(
        findServerType(AuthenticatorType.appflowyCloud),
        findsOneWidget,
      );
    });
  });
}
