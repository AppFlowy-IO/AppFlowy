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
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:integration_test/integration_test.dart';
import '../util/dir.dart';
import '../util/mock/mock_file_picker.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const pageName = 'Sample';
  final email = '${uuid()}@appflowy.io';

// The test will create a new document called Sample, and sync it to the server.
// Then the test will logout the user, and login with the same user. The data will
// be synced from the server.
  group('appflowy cloud document', () {
    testWidgets('sync local docuemnt to server', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloud,
        email: email,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePage();

      // create a new document called Sample
      await tester.createNewPageWithName(
        name: pageName,
        layout: ViewLayoutPB.Document,
      );

      // focus on the editor
      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText('hello world');

      await tester.pumpAndSettle();
      expect(find.text('hello world', findRichText: true), findsOneWidget);

      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.user);
      await tester.logout();
    });

    testWidgets('sync doc from server', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloud,
        email: email,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePage();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // The document will be synced from the server
      await tester.openPage(
        pageName,
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('hello world', findRichText: true), findsOneWidget);
    });
  });
}
