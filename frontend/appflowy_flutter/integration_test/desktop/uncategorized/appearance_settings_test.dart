import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/settings_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('appearance settings tests', () {
    testWidgets('after editing text field, button should be able to be clicked',
        (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapAnonymousSignInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();
      await tester.openSettings();

      await tester.openSettingsPage(SettingsPage.appearance);

      final dropDown = find.byKey(ThemeFontFamilySetting.popoverKey);
      await tester.tap(dropDown);
      await tester.pumpAndSettle();

      final textField = find.byKey(ThemeFontFamilySetting.textFieldKey);
      await tester.tap(textField);
      await tester.pumpAndSettle();

      await tester.enterText(textField, 'Abel');
      await tester.pumpAndSettle();
      final fontFamilyButton = find.byKey(const Key('Abel'));

      expect(fontFamilyButton, findsOneWidget);
      await tester.tap(fontFamilyButton);
      await tester.pumpAndSettle();

      // just switch the page and verify that the font family was set after that
      await tester.openSettingsPage(SettingsPage.files);
      await tester.openSettingsPage(SettingsPage.appearance);

      expect(find.textContaining('Abel'), findsOneWidget);
    });

    testWidgets('reset the font family', (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapAnonymousSignInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();
      await tester.openSettings();

      await tester.openSettingsPage(SettingsPage.appearance);

      final dropDown = find.byKey(ThemeFontFamilySetting.popoverKey);
      await tester.tap(dropDown);
      await tester.pumpAndSettle();

      final textField = find.byKey(ThemeFontFamilySetting.textFieldKey);
      await tester.tap(textField);
      await tester.pumpAndSettle();

      await tester.enterText(textField, 'Abel');
      await tester.pumpAndSettle();
      final fontFamilyButton = find.byKey(const Key('Abel'));

      expect(fontFamilyButton, findsOneWidget);
      await tester.tap(fontFamilyButton);
      await tester.pumpAndSettle();

      // just switch the page and verify that the font family was set after that
      await tester.openSettingsPage(SettingsPage.files);
      await tester.openSettingsPage(SettingsPage.appearance);

      final resetButton = find.byKey(ThemeFontFamilySetting.resetButtonKey);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // just switch the page and verify that the font family was set after that
      await tester.openSettingsPage(SettingsPage.files);
      await tester.openSettingsPage(SettingsPage.appearance);

      expect(
        find.textContaining(DefaultAppearanceSettings.kDefaultFontFamily),
        findsOneWidget,
      );
    });
  });
}
