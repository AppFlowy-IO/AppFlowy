// ignore_for_file: unused_import

import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/sign_in_anonymous_button.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:integration_test/integration_test.dart';
import '../util/database_test_op.dart';
import '../util/dir.dart';
import '../util/mock/mock_file_picker.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('appflowy cloud', () {
    testWidgets('anon user -> af cloud -> continue anon', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloud,
      );

      tester.expectToSeeText(LocaleKeys.signIn_loginStartWithAnonymous.tr());
      await tester.tapGoButton();
      await tester.expectToSeeHomePage();

      // reanme the name of the anon user
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.user);
      final userNameFinder = find.descendant(
        of: find.byType(SettingsUserView),
        matching: find.byType(UserNameInput),
      );
      await tester.enterText(userNameFinder, 'local_user');
      await tester.openSettingsPage(SettingsPage.user);
      await tester.tapEscButton();
      await tester.expectToSeeHomePage();

      // sign up with Google
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.user);
      await tester.tapGoogleLoginInButton();

      await tester.expectToSeeHomePage();

      // sign out
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.user);
      await tester.logout();
      await tester.pumpAndSettle();

      tester.expectToSeeText(LocaleKeys.signIn_continueAnonymousUser.tr());
      // tap the continue as anonymous button
      await tester.tapButton(find.byType(SignInAnonymousButton));

      await tester.expectToSeeHomePage();
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.user);
      final userNameInput = tester.widget(userNameFinder) as UserNameInput;
      expect(userNameInput.name, 'local_user');
    });
  });
}
