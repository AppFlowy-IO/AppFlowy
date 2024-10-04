// ignore_for_file: unused_import

import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_account_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../../../shared/dir.dart';
import '../../../shared/mock/mock_file_picker.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final email = '${uuid()}@appflowy.io';
  const inputContent = 'Hello world, this is a test document';

// The test will create a new document called Sample, and sync it to the server.
// Then the test will logout the user, and login with the same user. The data will
// be synced from the server.
  group('appflowy cloud document', () {
    testWidgets('sync local docuemnt to server', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
        email: email,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // create a new document called Sample
      await tester.createNewPage();

      // focus on the editor
      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText(inputContent);
      expect(find.text(inputContent, findRichText: true), findsOneWidget);

      // 6 seconds for data sync
      await tester.waitForSeconds(6);

      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.account);
      await tester.logout();
    });

    testWidgets('sync doc from server', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
        email: email,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePage();

      // the latest document will be opened, so the content must be the inputContent
      await tester.pumpAndSettle();
      expect(find.text(inputContent, findRichText: true), findsOneWidget);
    });
  });
}
