import 'package:appflowy/user/presentation/sign_in_screen.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/sync_setting_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';

extension AppFlowyAuthTest on WidgetTester {
  Future<void> tapGoogleLoginInButton() async {
    await tapButton(find.byType(GoogleSignUpButton));
  }

  Future<void> tapSignInAsGuest() async {
    await tapButton(find.byType(SignInAsGuestButton));
  }

  void expectToSeeGoogleLoginButton() {
    expect(find.byType(GoogleSignUpButton), findsOneWidget);
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

  void assertEnableSyncSwitchValue(bool value) {
    assertSwitchValue(
      find.descendant(
        of: find.byType(EnableSync),
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

  Future<void> toggleEnableSync() async {
    final finder = find.descendant(
      of: find.byType(EnableSync),
      matching: find.byWidgetPredicate((widget) => widget is Switch),
    );

    await tapButton(finder);
  }
}
