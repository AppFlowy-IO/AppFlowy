import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/keyboard.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('hotkeys test', () {
    testWidgets('toggle theme mode', (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapAnonymousSignInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.workspace);
      await tester.pumpAndSettle();

      final appFinder = find.byType(MaterialApp).first;
      ThemeMode? themeMode = tester.widget<MaterialApp>(appFinder).themeMode;

      expect(themeMode, ThemeMode.system);

      await tester.tapButton(
        find.bySemanticsLabel(
          LocaleKeys.settings_workspacePage_appearance_options_light.tr(),
        ),
      );
      await tester.pumpAndSettle();

      themeMode = tester.widget<MaterialApp>(appFinder).themeMode;
      expect(themeMode, ThemeMode.light);

      await tester.tapButton(
        find.bySemanticsLabel(
          LocaleKeys.settings_workspacePage_appearance_options_dark.tr(),
        ),
      );
      await tester.pumpAndSettle();

      themeMode = tester.widget<MaterialApp>(appFinder).themeMode;
      expect(themeMode, ThemeMode.dark);

      await tester.tap(find.byType(SettingsDialog));
      await tester.pumpAndSettle();

      await FlowyTestKeyboard.simulateKeyDownEvent(
        [
          Platform.isMacOS
              ? LogicalKeyboardKey.meta
              : LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyL,
        ],
        tester: tester,
        withKeyUp: true,
      );
      await tester.pumpAndSettle();

      themeMode = tester.widget<MaterialApp>(appFinder).themeMode;
      expect(themeMode, ThemeMode.light);
    });

    testWidgets('show or hide home menu', (tester) async {
      await tester.initializeAppFlowy();

      await tester.tapAnonymousSignInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      await tester.pumpAndSettle();

      expect(find.byType(HomeSideBar), findsOneWidget);

      await FlowyTestKeyboard.simulateKeyDownEvent(
        [
          Platform.isMacOS
              ? LogicalKeyboardKey.meta
              : LogicalKeyboardKey.control,
          LogicalKeyboardKey.backslash,
        ],
        tester: tester,
        withKeyUp: true,
      );

      await tester.pumpAndSettle();

      expect(find.byType(HomeSideBar), findsNothing);
    });
  });
}
