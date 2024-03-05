// ignore_for_file: unused_import

import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_workspace.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../util/database_test_op.dart';
import '../util/dir.dart';
import '../util/emoji.dart';
import '../util/mock/mock_file_picker.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final email = '${uuid()}@appflowy.io';

  group('collaborative workspace', () {
    // only run the test when the feature flag is on
    if (!FeatureFlag.collaborativeWorkspace.isOn) {
      return;
    }

    testWidgets('create a new workspace', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
        email: email,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      const name = 'AppFlowy.IO';
      await tester.createCollaborativeWorkspace(name);

      // see the success message
      final success = find.text(LocaleKeys.workspace_createSuccess.tr());
      expect(success, findsOneWidget);
      await tester.pumpUntilNotFound(success);

      await tester.openCollaborativeWorkspaceMenu();
      final items = find.byType(WorkspaceMenuItem);
      expect(items, findsNWidgets(2));
      expect(
        (items.evaluate().last.widget as WorkspaceMenuItem).workspace.name,
        name,
      );
      await tester.closeCollaborativeWorkspaceMenu();
    });
  });
}
