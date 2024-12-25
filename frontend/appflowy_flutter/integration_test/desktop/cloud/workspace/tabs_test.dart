import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/loading.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:appflowy/workspace/presentation/home/tabs/flowy_tab.dart';
import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/constants.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tabs', () {
    testWidgets('close other tabs before opening a new workspace',
        (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      const name = 'AppFlowy.IO';
      // the workspace will be opened after created
      await tester.createCollaborativeWorkspace(name);

      final loading = find.byType(Loading);
      await tester.pumpUntilNotFound(loading);

      // create new tabs in the workspace
      expect(find.byType(FlowyTab), findsNothing);

      const documentOneName = 'document one';
      const documentTwoName = 'document two';
      await tester.createNewPageInSpace(
        spaceName: Constants.generalSpaceName,
        layout: ViewLayoutPB.Document,
        pageName: documentOneName,
      );
      await tester.createNewPageInSpace(
        spaceName: Constants.generalSpaceName,
        layout: ViewLayoutPB.Document,
        pageName: documentTwoName,
      );

      /// Open second menu item in a new tab
      await tester.openAppInNewTab(documentOneName, ViewLayoutPB.Document);

      /// Open third menu item in a new tab
      await tester.openAppInNewTab(documentTwoName, ViewLayoutPB.Document);

      expect(
        find.descendant(
          of: find.byType(TabsManager),
          matching: find.byType(FlowyTab),
        ),
        findsNWidgets(2),
      );

      // switch to the another workspace
      final Finder items = find.byType(WorkspaceMenuItem);
      await tester.openCollaborativeWorkspaceMenu();
      await tester.pumpUntilFound(items);
      expect(items, findsNWidgets(2));

      // open the first workspace
      await tester.tap(items.first);
      await tester.pumpUntilNotFound(loading);

      expect(find.byType(FlowyTab), findsNothing);
    });
  });
}
