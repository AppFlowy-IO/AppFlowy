// ignore_for_file: unused_import

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_account_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../desktop/board/board_hide_groups_test.dart';
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
      await tester.openSettingsPage(SettingsPage.account);
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

      // Enable editing username
      final editUsernameFinder = find.descendant(
        of: find.byType(UserProfileSetting),
        matching: find.byFlowySvg(FlowySvgs.edit_s),
      );
      await tester.tap(editUsernameFinder);
      await tester.pumpAndSettle();

      final userNameFinder = find.descendant(
        of: find.byType(UserProfileSetting),
        matching: find.byType(FlowyTextField),
      );
      await tester.enterText(userNameFinder, name);
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.button_save.tr()));
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
    await tester.openSettingsPage(SettingsPage.account);

    // Verify name
    final profileSetting =
        tester.widget(find.byType(UserProfileSetting)) as UserProfileSetting;

    expect(profileSetting.name, name);
  });
}
