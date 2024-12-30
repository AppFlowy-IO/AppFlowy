import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/util.dart';
import '../../../shared/workspace.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('workspace icon:', () {
    testWidgets('remove icon from workspace', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      await tester.openWorkspaceMenu();

      // click the workspace icon
      await tester.tapButton(
        find.descendant(
          of: find.byType(WorkspaceMenuItem),
          matching: find.byType(WorkspaceIcon),
        ),
      );
      // click the remove icon button
      await tester.tapButton(
        find.text(LocaleKeys.button_remove.tr()),
      );

      // nothing should happen
      expect(
        find.text(LocaleKeys.workspace_updateIconSuccess.tr()),
        findsNothing,
      );
    });
  });
}
