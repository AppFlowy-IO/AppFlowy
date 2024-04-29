import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_setting.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/direction_setting.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu_element.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';

extension AppFlowySettings on WidgetTester {
  /// Open settings page
  Future<void> openSettings() async {
    final settingsButton = find.byType(UserSettingButton);
    expect(settingsButton, findsOneWidget);
    await tapButton(settingsButton);
    final settingsDialog = find.byType(SettingsDialog);
    expect(settingsDialog, findsOneWidget);
    return;
  }

  /// Open the page that insides the settings page
  Future<void> openSettingsPage(SettingsPage page) async {
    final button = find.byWidgetPredicate(
      (widget) => widget is SettingsMenuElement && widget.page == page,
    );
    expect(button, findsOneWidget);
    await tapButton(button);
    return;
  }

  Future<void> expectNoSettingsPage(SettingsPage page) async {
    final button = find.byWidgetPredicate(
      (widget) => widget is SettingsMenuElement && widget.page == page,
    );
    expect(button, findsNothing);
    return;
  }

  /// Restore the AppFlowy data storage location
  Future<void> restoreLocation() async {
    final button =
        find.byTooltip(LocaleKeys.settings_files_recoverLocationTooltips.tr());
    expect(button, findsOneWidget);
    await tapButton(button);
    return;
  }

  Future<void> tapOpenFolderButton() async {
    final button = find.text(LocaleKeys.settings_files_open.tr());
    expect(button, findsOneWidget);
    await tapButton(button);
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
    // final uni = find.byType(UserNameInput);
    // expect(uni, findsOneWidget);
    // await tap(uni);
    // await enterText(uni, name);
    // await wait(300); //
    // await testTextInput.receiveAction(TextInputAction.done);
    // await pumpAndSettle();
  }

  // go to settings page and toggle enable RTL toolbar items
  Future<void> toggleEnableRTLToolbarItems() async {
    await openSettings();
    await openSettingsPage(SettingsPage.appearance);

    final switchButton =
        find.byKey(EnableRTLToolbarItemsSetting.enableRTLSwitchKey);
    expect(switchButton, findsOneWidget);
    await tapButton(switchButton);

    // tap anywhere to close the settings page
    await tapAt(Offset.zero);
    await pumpAndSettle();
  }
}
