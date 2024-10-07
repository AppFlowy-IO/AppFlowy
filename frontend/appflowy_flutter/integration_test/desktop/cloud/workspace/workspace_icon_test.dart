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
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
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
import 'package:universal_platform/universal_platform.dart';

import '../../../shared/constants.dart';
import '../../../shared/database_test_op.dart';
import '../../../shared/dir.dart';
import '../../../shared/emoji.dart';
import '../../../shared/mock/mock_file_picker.dart';
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
      await tester.tapButton(find.byType(WorkspaceIcon).first);
      // click the remove icon button
      await tester.tapButton(
        find.text(LocaleKeys.document_plugins_cover_removeIcon.tr()),
      );

      // nothing should happen
      expect(
        find.text(LocaleKeys.workspace_updateIconSuccess.tr()),
        findsNothing,
      );
    });
  });
}
