import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';

enum SettingsPage {
  appearance,
  language,
  files,
  user,
}

extension on SettingsPage {
  String get name {
    switch (this) {
      case SettingsPage.appearance:
        return LocaleKeys.settings_menu_appearance.tr();
      case SettingsPage.language:
        return LocaleKeys.settings_menu_language.tr();
      case SettingsPage.files:
        return LocaleKeys.settings_menu_files.tr();
      case SettingsPage.user:
        return LocaleKeys.settings_menu_user.tr();
    }
  }
}

extension AppFlowySettings on WidgetTester {
  /// Open settings page
  Future<void> openSettings() async {
    final settingsButton = find.byTooltip(LocaleKeys.settings_menu_open.tr());
    expect(settingsButton, findsOneWidget);
    await tapButton(settingsButton);
    final settingsDialog = find.byType(SettingsDialog);
    expect(settingsDialog, findsOneWidget);
    return;
  }

  /// Open the page taht insides the settings page
  Future<void> openSettingsPage(SettingsPage page) async {
    final button = find.text(page.name, findRichText: true);
    expect(button, findsOneWidget);
    await tapButton(button);
    return;
  }

  /// Restore the AppFlowy data storage location
  Future<void> restoreLocation() async {
    final restoreButton =
        find.byTooltip(LocaleKeys.settings_files_restoreLocation.tr());
    expect(restoreButton, findsOneWidget);
    await tapButton(restoreButton);
    return;
  }
}
