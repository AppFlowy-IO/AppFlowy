import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar.dart';
import 'package:appflowy/workspace/presentation/settings/settings_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
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
      await tester.openSettingsPage(SettingsPage.appearance);
      await tester.pumpAndSettle();

      tester.expectToSeeText(
        LocaleKeys.settings_appearance_themeMode_system.tr(),
      );

      await tester.tapButton(
        find.bySemanticsLabel(
          LocaleKeys.settings_appearance_themeMode_system.tr(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tapButton(
        find.bySemanticsLabel(
          LocaleKeys.settings_appearance_themeMode_dark.tr(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

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
      );

      await tester.pumpAndSettle();

      tester.expectToSeeText(
        LocaleKeys.settings_appearance_themeMode_light.tr(),
      );
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
      );

      await tester.pumpAndSettle();

      expect(find.byType(HomeSideBar), findsNothing);
    });
  });
}
