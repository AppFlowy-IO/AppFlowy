import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_account_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

extension AppFlowyAuthTest on WidgetTester {
  Future<void> tapGoogleLoginInButton() async {
    await tapButton(
      find.byKey(signInWithGoogleButtonKey),
    );
  }

  /// Requires being on the SettingsPage.account of the SettingsDialog
  Future<void> logout() async {
    final scrollable = find.findSettingsScrollable();
    await scrollUntilVisible(
      find.byType(SignInOutButton),
      100,
      scrollable: scrollable,
    );

    await tapButton(find.byType(SignInOutButton));

    expectToSeeText(LocaleKeys.button_ok.tr());
    await tapButtonWithName(LocaleKeys.button_ok.tr());
  }

  Future<void> tapSignInAsGuest() async {
    await tapButton(find.byType(SignInAnonymousButtonV2));
  }

  void expectToSeeGoogleLoginButton() {
    expect(find.byKey(signInWithGoogleButtonKey), findsOneWidget);
  }

  void assertSwitchValue(Finder finder, bool value) {
    final Switch switchWidget = widget(finder);
    final isSwitched = switchWidget.value;
    assert(isSwitched == value);
  }

  void assertToggleValue(Finder finder, bool value) {
    final Toggle switchWidget = widget(finder);
    final isSwitched = switchWidget.value;
    assert(isSwitched == value);
  }

  void assertAppFlowyCloudEnableSyncSwitchValue(bool value) {
    assertToggleValue(
      find.descendant(
        of: find.byType(AppFlowyCloudEnableSync),
        matching: find.byWidgetPredicate((widget) => widget is Toggle),
      ),
      value,
    );
  }

  Future<void> toggleEnableSync(Type syncButton) async {
    final finder = find.descendant(
      of: find.byType(syncButton),
      matching: find.byWidgetPredicate((widget) => widget is Toggle),
    );

    await tapButton(finder);
  }
}
