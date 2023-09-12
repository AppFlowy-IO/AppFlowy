import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/sync_setting_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';

extension AppFlowyAuthTest on WidgetTester {
  Future<void> tapGoogleLoginInButton() async {
    await tapButton(find.byKey(const Key('signInWithGoogleButton')));
  }

  Future<void> tapSignInAsGuest() async {
    await tapButton(find.byType(SignInAnonymousButton));
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
