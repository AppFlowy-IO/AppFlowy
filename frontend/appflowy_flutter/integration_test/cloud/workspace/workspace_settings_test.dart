// ignore_for_file: unused_import

import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/loading.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/sidebar_workspace.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_workspace_view.dart';
import 'package:appflowy/workspace/presentation/settings/shared/setting_list_tile.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
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

  group('workspace settings: ', () {
    testWidgets(
      'change document width',
      (tester) async {
        await tester.initializeAppFlowy(
          cloudType: AuthenticatorType.appflowyCloudSelfHost,
        );
        await tester.tapGoogleLoginInButton();
        await tester.expectToSeeHomePageWithGetStartedPage();

        await tester.openSettings();
        await tester.openSettingsPage(SettingsPage.workspace);

        final documentWidthSettings = find.findTextInFlowyText(
          LocaleKeys.settings_appearance_documentSettings_width.tr(),
        );

        final scrollable = find.ancestor(
          of: find.byType(SettingsWorkspaceView),
          matching: find.descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          ),
        );

        await tester.scrollUntilVisible(
          documentWidthSettings,
          0,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();

        // change the document width
        final slider = find.byType(Slider);
        final oldValue = tester.widget<Slider>(slider).value;
        await tester.drag(slider, const Offset(-100, 0));
        await tester.pumpAndSettle();

        // check the document width is changed
        expect(tester.widget<Slider>(slider).value, lessThan(oldValue));

        // click the reset button
        final resetButton = find.descendant(
          of: find.byType(DocumentPaddingSetting),
          matching: find.byType(SettingsResetButton),
        );
        await tester.tap(resetButton);
        await tester.pumpAndSettle();

        // check the document width is reset
        expect(
          tester.widget<Slider>(slider).value,
          EditorStyleCustomizer.maxDocumentWidth,
        );
      },
    );
  });
}
