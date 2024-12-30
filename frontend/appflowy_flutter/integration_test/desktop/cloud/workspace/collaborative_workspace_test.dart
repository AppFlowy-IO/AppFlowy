import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/loading.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('collaborative workspace:', () {
    // combine the create and delete workspace test to reduce the time
    testWidgets('create a new workspace, open it and then delete it',
        (tester) async {
      // only run the test when the feature flag is on
      if (!FeatureFlag.collaborativeWorkspace.isOn) {
        return;
      }

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

      Finder success;

      final Finder items = find.byType(WorkspaceMenuItem);

      // delete the newly created workspace
      await tester.openCollaborativeWorkspaceMenu();
      await tester.pumpUntilFound(items);

      expect(items, findsNWidgets(2));
      expect(
        tester.widget<WorkspaceMenuItem>(items.last).workspace.name,
        name,
      );

      final secondWorkspace = find.byType(WorkspaceMenuItem).last;
      await tester.hoverOnWidget(
        secondWorkspace,
        onHover: () async {
          // click the more button
          final moreButton = find.byType(WorkspaceMoreActionList);
          expect(moreButton, findsOneWidget);
          await tester.tapButton(moreButton);
          // click the delete button
          final deleteButton = find.text(LocaleKeys.button_delete.tr());
          expect(deleteButton, findsOneWidget);
          await tester.tapButton(deleteButton);
          // see the delete confirm dialog
          final confirm =
              find.text(LocaleKeys.workspace_deleteWorkspaceHintText.tr());
          expect(confirm, findsOneWidget);
          await tester.tapButton(find.text(LocaleKeys.button_ok.tr()));
          // delete success
          success = find.text(LocaleKeys.workspace_createSuccess.tr());
          await tester.pumpUntilFound(success);
          expect(success, findsOneWidget);
          await tester.pumpUntilNotFound(success);
        },
      );
    });

    testWidgets('check the member count immediately after creating a workspace',
        (tester) async {
      // only run the test when the feature flag is on
      if (!FeatureFlag.collaborativeWorkspace.isOn) {
        return;
      }

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

      await tester.openCollaborativeWorkspaceMenu();

      // expect to see the member count
      final memberCount = find.text('1 member');
      expect(memberCount, findsNWidgets(2));
    });

    testWidgets('only display one menu item in the workspace menu',
        (tester) async {
      // only run the test when the feature flag is on
      if (!FeatureFlag.collaborativeWorkspace.isOn) {
        return;
      }

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

      await tester.openCollaborativeWorkspaceMenu();

      // hover on the workspace and click the more button
      final workspaceItem = find.byWidgetPredicate(
        (w) => w is WorkspaceMenuItem && w.workspace.name == name,
      );
      await tester.hoverOnWidget(
        workspaceItem,
        onHover: () async {
          final moreButton = find.byWidgetPredicate(
            (w) => w is WorkspaceMoreActionList && w.workspace.name == name,
          );
          expect(moreButton, findsOneWidget);
          await tester.tapButton(moreButton);

          // click it again
          await tester.tapButton(moreButton);

          // nothing should happen
          expect(
            find.text(LocaleKeys.button_rename.tr()),
            findsOneWidget,
          );
        },
      );
    });
  });
}
