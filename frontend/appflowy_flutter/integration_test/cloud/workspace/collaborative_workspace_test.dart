// ignore_for_file: unused_import

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/loading.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_workspace.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../../shared/database_test_op.dart';
import '../../shared/dir.dart';
import '../../shared/emoji.dart';
import '../../shared/mock/mock_file_picker.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('collaborative workspace', () {
    // combine the create and delete workspace test to reduce the time
    testWidgets('create a new workspace, open it and then delete it',
        (tester) async {
      final email = '${uuid()}@appflowy.io';

      // only run the test when the feature flag is on
      if (!FeatureFlag.collaborativeWorkspace.isOn) {
        return;
      }

      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
        email: email,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      const name = 'AppFlowy.IO';
      // the workspace will be opened after created
      await tester.createCollaborativeWorkspace(name);

      final loading = find.byType(Loading);
      await tester.pumpUntilNotFound(loading);

      Finder success;

      // delete the newly created workspace
      await tester.openCollaborativeWorkspaceMenu();
      final Finder items = find.byType(WorkspaceMenuItem);
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

    testWidgets('switch workspace multiple times', (tester) async {
      final email = '${uuid()}@appflowy.io';

      // only run the test when the feature flag is on
      if (!FeatureFlag.collaborativeWorkspace.isOn) {
        return;
      }

      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
        email: email,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      Future<void> createWorkspaceAndPages(
        String workspaceName,
        List<String> pageNames,
      ) async {
        await tester.createCollaborativeWorkspace(workspaceName);
        final loading = find.byType(Loading);
        await tester.pumpUntilNotFound(loading);
        for (final pageName in pageNames) {
          await tester.createNewPageWithNameUnderParent(name: pageName);
        }
      }

      // wait for the workspace to be created
      await tester.waitForSeconds(1);

      const workspace1 = 'Workspace 1';
      const workspace2 = 'Workspace 2';
      const workspace3 = 'Workspace 3';
      final pageInWorkspace1 = ['Page 1', 'Page 2'];
      final pageInWorkspace2 = ['Page 3', 'Page 4'];
      final pageInWorkspace3 = ['Page 5', 'Page 6'];

      await createWorkspaceAndPages(workspace1, pageInWorkspace1);
      await createWorkspaceAndPages(workspace2, pageInWorkspace2);
      await createWorkspaceAndPages(workspace3, pageInWorkspace3);

      Future<void> switchWorkspaceAndCheckPages(
        String workspaceName,
        List<String> pageNames,
      ) async {
        await tester.openCollaborativeWorkspaceMenu();
        final item = find.byWidgetPredicate(
          (widget) =>
              widget is WorkspaceMenuItem &&
              widget.workspace.name == workspaceName,
        );
        await tester.tapButton(item, milliseconds: 0);

        // check workspace name
        final workspace = find.byWidgetPredicate(
          (widget) =>
              widget is SidebarSwitchWorkspaceButton &&
              widget.currentWorkspace.name == workspaceName,
        );
        expect(workspace, findsOneWidget);

        for (final pageName in pageNames) {
          final page = tester.findPageName(pageName);
          expect(page, findsOneWidget);
        }
      }

      for (var i = 0; i <= 15; i++) {
        if (i % 3 == 0) {
          await switchWorkspaceAndCheckPages(workspace1, pageInWorkspace1);
        } else if (i % 3 == 1) {
          await switchWorkspaceAndCheckPages(workspace2, pageInWorkspace2);
        } else {
          await switchWorkspaceAndCheckPages(workspace3, pageInWorkspace3);
        }
      }
    });
  });
}
