import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/custom_cover_picker_bloc.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_actionable_input.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final email = '${uuid()}@appflowy.io';

  group('Settings', () {
    testWidgets('delete collaborative workspace', (tester) async {
      if (!FeatureFlag.collaborativeWorkspace.isOn) {
        return;
      }

      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
        email: email,
      );

      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // Create new workspace
      const name = 'AppFlowy.IO';
      await tester.createCollaborativeWorkspace(name);

      final loading = find.byType(Loading);
      await tester.pumpUntilNotFound(loading);

      // Open settings dialog
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.workspace);

      // Rename workspace
      final nameFinder = find.descendant(
        of: find.byType(SettingsActionableInput),
        matching: find.byType(FlowyTextField),
      );
      await tester.enterText(nameFinder, 'AppFlowy.IO 2');

      // Save changes
      await tester.tap(find.text(LocaleKeys.button_save.tr()));

      // Delete workspace
      final deleteFinder = find.text(
        LocaleKeys.settings_workspacePage_manageWorkspace_deleteWorkspace.tr(),
      );

      await tester.scrollUntilVisible(
        deleteFinder,
        100,
        scrollable: find.findSettingsScrollable(),
      );
      await tester.ensureVisible(deleteFinder);

      await tester.tap(deleteFinder);
      await tester.pump(const Duration(milliseconds: 200));

      // Confirm deletion
      await tester.tap(find.text(LocaleKeys.button_confirm.tr()));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpUntilNotFound(loading);

      await tester.openCollaborativeWorkspaceMenu();
      final Finder items = find.byType(WorkspaceMenuItem);
      expect(items, findsNWidgets(1));
    });
  });
}
