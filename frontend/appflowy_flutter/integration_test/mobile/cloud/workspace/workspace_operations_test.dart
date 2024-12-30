import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/constants.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('workspace operations:', () {
    testWidgets('create a new workspace', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // click the create a new workspace button
      await tester.tapButton(find.text(Constants.defaultWorkspaceName));
      await tester.tapButton(find.text(LocaleKeys.workspace_create.tr()));

      // input the new workspace name
      final inputField = find.byType(TextFormField);
      const newWorkspaceName = 'AppFlowy';
      await tester.enterText(inputField, newWorkspaceName);
      await tester.pumpAndSettle();

      // wait for the workspace to be created
      await tester.pumpUntilFound(
        find.text(LocaleKeys.workspace_createSuccess.tr()),
      );

      // expect to see the new workspace
      expect(find.text(newWorkspaceName), findsOneWidget);
    });
  });
}
