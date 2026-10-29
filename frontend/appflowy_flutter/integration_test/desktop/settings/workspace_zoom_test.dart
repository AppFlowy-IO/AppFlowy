import 'package:appflowy/startup/tasks/app_window_size_manager.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App zoom setting:', () {
    Future<void> resetAppFlowyScaleFactor(
      WindowSizeManager windowSizeManager,
    ) async {
      appflowyScaleFactor.value = 1.0;
      await windowSizeManager.setScaleFactor(1.0);
    }

    testWidgets('zoom in, out and reset from the workspace settings',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // this value can't be defined in the setUp method, because the
      // windowSizeManager is not initialized yet.
      final windowSizeManager = WindowSizeManager();
      await resetAppFlowyScaleFactor(windowSizeManager);

      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.workspace);
      await tester.pumpAndSettle();

      // zoom in twice -> 120%
      for (var i = 0; i < 2; i++) {
        await tester.tapButton(find.byKey(const Key('ZoomIncreaseButton')));
      }
      expect(appflowyScaleFactor.value, 1.2);
      expect(await windowSizeManager.getScaleFactor(), 1.2);

      // zoom out once -> 110%
      await tester.tapButton(find.byKey(const Key('ZoomDecreaseButton')));
      expect(appflowyScaleFactor.value, 1.1);
      expect(await windowSizeManager.getScaleFactor(), 1.1);

      // reset -> 100%
      await tester.tapButton(find.byKey(const Key('ZoomResetButton')));
      expect(appflowyScaleFactor.value, 1.0);
      expect(await windowSizeManager.getScaleFactor(), 1.0);
    });

    testWidgets(
        'the displayed zoom level updates when zoom is changed via hotkey '
        'while the settings page is open', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      final windowSizeManager = WindowSizeManager();
      await resetAppFlowyScaleFactor(windowSizeManager);

      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.workspace);
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);

      // zoom in via the hotkey (not the settings buttons) while the
      // settings page is still open, and confirm the label updates.
      final keycode = zoomInKeyCodes.firstWhere(
        (keycode) =>
            !UniversalPlatform.isLinux ||
            keycode.logicalKey != LogicalKeyboardKey.add,
      );
      await tester.simulateKeyEvent(
        keycode.logicalKey,
        isControlPressed: !UniversalPlatform.isMacOS,
        isMetaPressed: UniversalPlatform.isMacOS,
        physicalKey: keycode.logicalKey == LogicalKeyboardKey.add
            ? PhysicalKeyboardKey.equal
            : null,
      );
      await tester.pumpAndSettle();

      expect(appflowyScaleFactor.value, 1.1);
      expect(find.text('110%'), findsOneWidget);
    });
  });
}
