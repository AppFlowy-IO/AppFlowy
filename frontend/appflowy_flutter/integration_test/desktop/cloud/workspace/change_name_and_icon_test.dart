// ignore_for_file: unused_import

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../../../shared/mock/mock_file_picker.dart';
import '../../../shared/util.dart';
import '../../../shared/workspace.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const icon = '😄';
  const name = 'AppFlowy';
  final email = '${uuid()}@appflowy.io';

  testWidgets('change name and icon', (tester) async {
    // only run the test when the feature flag is on
    if (!FeatureFlag.collaborativeWorkspace.isOn) {
      return;
    }

    await tester.initializeAppFlowy(
      cloudType: AuthenticatorType.appflowyCloudSelfHost,
      email: email, // use the same email to check the next test
    );

    await tester.tapGoogleLoginInButton();
    await tester.expectToSeeHomePageWithGetStartedPage();

    var workspaceIcon = tester.widget<WorkspaceIcon>(
      find.byType(WorkspaceIcon),
    );
    expect(workspaceIcon.workspace.icon, '');

    await tester.openWorkspaceMenu();
    await tester.changeWorkspaceIcon(icon);
    await tester.changeWorkspaceName(name);

    workspaceIcon = tester.widget<WorkspaceIcon>(
      find.byType(WorkspaceIcon),
    );
    expect(workspaceIcon.workspace.icon, icon);
    expect(find.findTextInFlowyText(name), findsOneWidget);
  });

  testWidgets('verify the result again after relaunching', (tester) async {
    // only run the test when the feature flag is on
    if (!FeatureFlag.collaborativeWorkspace.isOn) {
      return;
    }

    await tester.initializeAppFlowy(
      cloudType: AuthenticatorType.appflowyCloudSelfHost,
      email: email, // use the same email to check the next test
    );

    await tester.tapGoogleLoginInButton();
    await tester.expectToSeeHomePageWithGetStartedPage();

    // check the result again
    final workspaceIcon = tester.widget<WorkspaceIcon>(
      find.byType(WorkspaceIcon),
    );
    expect(workspaceIcon.workspace.icon, icon);
    expect(workspaceIcon.workspace.name, name);
  });
}
