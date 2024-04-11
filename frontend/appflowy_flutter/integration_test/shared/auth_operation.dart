import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_supabase_cloud.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_user_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';
import 'expectation.dart';

extension AppFlowyAuthTest on WidgetTester {
  Future<void> tapGoogleLoginInButton() async {
    await tapButton(find.byKey(const Key('signInWithGoogleButton')));
  }

  Future<void> logout() async {
    await tapButton(find.byType(SettingLogoutButton));

    expectToSeeText(LocaleKeys.button_ok.tr());
    await tapButtonWithName(LocaleKeys.button_ok.tr());
  }

  Future<void> tapSignInAsGuest() async {
    await tapButton(find.byType(SignInAnonymousButtonV2));
  }

  void expectToSeeGoogleLoginButton() {
    expect(find.byKey(const Key('signInWithGoogleButton')), findsOneWidget);
  }

  void assertSwitchValue(Finder finder, bool value) {
    final Switch switchWidget = widget(finder);
    final isSwitched = switchWidget.value;
    assert(isSwitched == value);
  }

  void assertEnableEncryptSwitchValue(bool value) {
    assertSwitchValue(
      find.descendant(
        of: find.byType(EnableEncrypt),
        matching: find.byWidgetPredicate((widget) => widget is Switch),
      ),
      value,
    );
  }

  void assertSupabaseEnableSyncSwitchValue(bool value) {
    assertSwitchValue(
      find.descendant(
        of: find.byType(SupabaseEnableSync),
        matching: find.byWidgetPredicate((widget) => widget is Switch),
      ),
      value,
    );
  }

  void assertAppFlowyCloudEnableSyncSwitchValue(bool value) {
    assertSwitchValue(
      find.descendant(
        of: find.byType(AppFlowyCloudEnableSync),
        matching: find.byWidgetPredicate((widget) => widget is Switch),
      ),
      value,
    );
  }

  Future<void> toggleEnableEncrypt() async {
    final finder = find.descendant(
      of: find.byType(EnableEncrypt),
      matching: find.byWidgetPredicate((widget) => widget is Switch),
    );

    await tapButton(finder);
  }

  Future<void> toggleEnableSync(Type syncButton) async {
    final finder = find.descendant(
      of: find.byType(syncButton),
      matching: find.byWidgetPredicate((widget) => widget is Switch),
    );

    await tapButton(finder);
  }
}
