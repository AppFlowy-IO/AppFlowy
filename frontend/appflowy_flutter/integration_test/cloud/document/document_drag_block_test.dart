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

  group('document drag block: ', () {
    testWidgets('drag block to the top', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // open getting started page
      await tester.openPage(Constants.gettingStartedPageName);

      // before move
      final beforeMoveBlock = tester.editor.getNodeAtPath([1]);

      // move the desktop guide to the top, above the getting started
      await tester.editor.dragBlock(
        [1],
        const Offset(20, -80),
      );

      // wait for the move animation to complete
      await tester.pumpAndSettle(Durations.short1);

      // check if the block is moved to the top
      final afterMoveBlock = tester.editor.getNodeAtPath([0]);
      expect(afterMoveBlock.delta, beforeMoveBlock.delta);
    });

    testWidgets('drag block to other block\'s child', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // open getting started page
      await tester.openPage(Constants.gettingStartedPageName);

      // before move
      final beforeMoveBlock = tester.editor.getNodeAtPath([10]);

      // move the checkbox to the child of the block at path [9]
      await tester.editor.dragBlock(
        [10],
        const Offset(80, -30),
      );

      // wait for the move animation to complete
      await tester.pumpAndSettle(Durations.short1);

      // check if the block is moved to the child of the block at path [9]
      final afterMoveBlock = tester.editor.getNodeAtPath([9, 0]);
      expect(afterMoveBlock.delta, beforeMoveBlock.delta);
    });
  });
}
