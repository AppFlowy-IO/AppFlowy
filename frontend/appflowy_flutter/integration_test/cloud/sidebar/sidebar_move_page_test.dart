// ignore_for_file: unused_import

import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/loading.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/sidebar_workspace.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../../shared/constants.dart';
import '../../shared/database_test_op.dart';
import '../../shared/dir.dart';
import '../../shared/emoji.dart';
import '../../shared/mock/mock_file_picker.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('sidebar move page: ', () {
    testWidgets('create a new document and move it to Getting started',
        (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      const pageName = 'Document';

      await tester.createNewPageInSpace(
        spaceName: Constants.generalSpaceName,
        layout: ViewLayoutPB.Document,
        pageName: pageName,
      );

      // click the ... button and move to Getting started
      await tester.hoverOnPageName(
        pageName,
        onHover: () async {
          await tester.tapPageOptionButton();
          await tester.tapButtonWithName(
            LocaleKeys.disclosureAction_moveTo.tr(),
          );
        },
      );

      // expect to see two pages
      // 1. Getting started
      // 2. To-dos
      final gettingStarted = find.text(Constants.gettingStartedPageName);
      // one is in the sidebar, the other is in the move to page list
      expect(gettingStarted, findsNWidgets(2));
      final toDos = find.text(Constants.toDosPageName);
      expect(toDos, findsNWidgets(2));

      // hover on the todos page, and will see a forbidden icon
      await tester.hoverOnWidget(
        toDos.last,
        onHover: () async {
          final tooltips = find.byTooltip(
            LocaleKeys.space_cannotMovePageToDatabase.tr(),
          );
          expect(tooltips, findsOneWidget);
        },
      );
      await tester.pumpAndSettle();

      // move the current page to Getting started
      await tester.tapButton(
        gettingStarted.last,
      );

      await tester.pumpAndSettle();

      // after moving, expect to not see the page name in the sidebar
      final page = tester.findPageName(pageName);
      expect(page, findsNothing);

      // click to expand the getting started page
      await tester.expandOrCollapsePage(
        pageName: Constants.gettingStartedPageName,
        layout: ViewLayoutPB.Document,
      );
      await tester.pumpAndSettle();

      // expect to see the page name in the getting started page
      final pageInGettingStarted = tester.findPageName(
        pageName,
        parentName: Constants.gettingStartedPageName,
      );
      expect(pageInGettingStarted, findsOneWidget);
    });
  });
}
