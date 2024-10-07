// ignore_for_file: unused_import

import 'dart:io';
import 'dart:ui';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/pages/account/account.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_account_view.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../shared/dir.dart';
import '../../../shared/mock/mock_file_picker.dart';
import '../../../shared/util.dart';
import '../../board/board_hide_groups_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('appflowy cloud', () {
    testWidgets('anon user', (tester) async {
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
        find.byType(AccountSignInOutButton),
        100,
        scrollable: find.findSettingsScrollable(),
      );

      await tester.tapButton(find.byType(AccountSignInOutButton));

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
