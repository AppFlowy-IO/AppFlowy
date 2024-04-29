// ignore_for_file: unused_import

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_account_view.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../desktop/board/board_hide_groups_test.dart';
import '../shared/dir.dart';
import '../shared/mock/mock_file_picker.dart';
import '../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('appflowy cloud', () {
    testWidgets('anon user and then sign in', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );

      tester.expectToSeeText(LocaleKeys.signIn_loginStartWithAnonymous.tr());
      await tester.tapAnonymousSignInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // reanme the name of the anon user
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.account);
      await tester.pumpAndSettle();

      await tester.enterUserName('local_user');

      await tester.tap(find.text(LocaleKeys.button_save.tr()));
      await tester.pumpAndSettle();

      // Scroll to sign-in
      await tester.scrollUntilVisible(
        find.byType(SignInOutButton),
        100,
        scrollable: find.findSettingsScrollable(),
      );

      await tester.tapButton(find.byType(SignInOutButton));

      // sign up with Google
      await tester.tapGoogleLoginInButton();

      // sign out
      await tester.expectToSeeHomePage();
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.account);

      // Scroll to sign-out
      await tester.scrollUntilVisible(
        find.byType(SignInOutButton),
        100,
        scrollable: find.findSettingsScrollable(),
      );

      await tester.logout();
      await tester.pumpAndSettle();

      // tap the continue as anonymous button
      await tester
          .tapButton(find.text(LocaleKeys.signIn_loginStartWithAnonymous.tr()));
      await tester.expectToSeeHomePage();

      // New anon user name
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.account);
      final userNameInput =
          tester.widget(find.byType(UserProfileSetting)) as UserProfileSetting;
      expect(userNameInput.name, 'Me');
    });
  });
}
