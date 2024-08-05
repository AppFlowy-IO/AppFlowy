import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_setting.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_account_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_workspace_view.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu_element.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flutter_test/flutter_test.dart';

import '../desktop/board/board_hide_groups_test.dart';
import 'base.dart';
import 'common_operations.dart';

extension AppFlowySettings on WidgetTester {
  /// Open settings page
  Future<void> openSettings() async {
    final settingsDialog = find.byType(SettingsDialog);
    // tap empty area to close the settings page
    while (settingsDialog.evaluate().isNotEmpty) {
      await tapAt(Offset.zero);
      await pumpAndSettle();
    }

    final settingsButton = find.byType(UserSettingButton);
    expect(settingsButton, findsOneWidget);
    await tapButton(settingsButton);

    expect(settingsDialog, findsOneWidget);
    return;
  }

  /// Open the page that insides the settings page
  Future<void> openSettingsPage(SettingsPage page) async {
    final button = find.byWidgetPredicate(
      (widget) => widget is SettingsMenuElement && widget.page == page,
    );

    await scrollUntilVisible(
      button,
      0,
      scrollable: find.findSettingsMenuScrollable(),
    );
    await pump();

    expect(button, findsOneWidget);
    await tapButton(button);
    return;
  }

  /// Restore the AppFlowy data storage location
  Future<void> restoreLocation() async {
    final button = find.text(LocaleKeys.settings_common_reset.tr());
    expect(button, findsOneWidget);
    await tapButton(button);
    await pumpAndSettle();

    final confirmButton = find.text(LocaleKeys.button_confirm.tr());
    expect(confirmButton, findsOneWidget);
    await tapButton(confirmButton);
    return;
  }

  Future<void> tapCustomLocationButton() async {
    final button = find.byTooltip(
      LocaleKeys.settings_files_changeLocationTooltips.tr(),
    );
    expect(button, findsOneWidget);
    await tapButton(button);
    return;
  }

  /// Enter user name
  Future<void> enterUserName(String name) async {
    // Enable editing username
    final editUsernameFinder = find.descendant(
      of: find.byType(UserProfileSetting),
      matching: find.byFlowySvg(FlowySvgs.edit_s),
    );
    await tap(editUsernameFinder);
    await pumpAndSettle();

    final userNameFinder = find.descendant(
      of: find.byType(UserProfileSetting),
      matching: find.byType(FlowyTextField),
    );
    await enterText(userNameFinder, name);
    await pumpAndSettle();

    await tap(find.text(LocaleKeys.button_save.tr()));
    await pumpAndSettle();
  }

  // go to settings page and toggle enable RTL toolbar items
  Future<void> toggleEnableRTLToolbarItems() async {
    await openSettings();
    await openSettingsPage(SettingsPage.workspace);

    final scrollable = find.findSettingsScrollable();
    await scrollUntilVisible(
      find.byType(EnableRTLItemsSwitcher),
      0,
      scrollable: scrollable,
    );

    final switcher = find.descendant(
      of: find.byType(EnableRTLItemsSwitcher),
      matching: find.byType(Toggle),
    );

    await tap(switcher);

    // tap anywhere to close the settings page
    await tapAt(Offset.zero);
    await pumpAndSettle();
  }
}
