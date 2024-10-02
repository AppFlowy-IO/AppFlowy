// ignore_for_file: unused_import

import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/base/view_page/app_bar_buttons.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_buttons.dart';
import 'package:appflowy/mobile/presentation/home/home.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/cover/document_immersive_cover_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_layout.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../../../shared/constants.dart';
import '../../../shared/dir.dart';
import '../../../shared/mock/mock_file_picker.dart';
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
