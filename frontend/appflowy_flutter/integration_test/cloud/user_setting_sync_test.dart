// ignore_for_file: unused_import

import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:integration_test/integration_test.dart';
import '../shared/database_test_op.dart';
import '../shared/dir.dart';
import '../shared/emoji.dart';
import '../shared/mock/mock_file_picker.dart';
import '../shared/util.dart';

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
      await tester.openSettingsPage(SettingsPage.user);
      // final userAvatarFinder = find.descendant(
      //   of: find.byType(SettingsUserView),
      //   matching: find.byType(UserAvatar),
      // );

      // Open icon picker dialog and select emoji
      // await tester.tap(userAvatarFinder);
      // await tester.pumpAndSettle();
      // await tester.tapEmoji('😁');
      // await tester.pumpAndSettle();
      // final UserAvatar userAvatar =
      //     tester.widget(userAvatarFinder) as UserAvatar;
      // expect(userAvatar.iconUrl, '😁');

      // enter user name
      final userNameFinder = find.descendant(
        of: find.byType(SettingsUserView),
        matching: find.byType(UserNameInput),
      );
      await tester.enterText(userNameFinder, name);
      await tester.pumpAndSettle();
      await tester.tapEscButton();

      // wait 2 seconds for the sync to finish
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
    await tester.openSettingsPage(SettingsPage.user);

    // verify icon
    // final userAvatarFinder = find.descendant(
    //   of: find.byType(SettingsUserView),
    //   matching: find.byType(UserAvatar),
    // );
    // final UserAvatar userAvatar = tester.widget(userAvatarFinder) as UserAvatar;
    // expect(userAvatar.iconUrl, '😁');

    // verify name
    final userNameFinder = find.descendant(
      of: find.byType(SettingsUserView),
      matching: find.byType(UserNameInput),
    );
    final UserNameInput userNameInput =
        tester.widget(userNameFinder) as UserNameInput;
    expect(userNameInput.name, name);
  });
}
