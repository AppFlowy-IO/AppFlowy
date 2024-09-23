import 'package:appflowy/startup/tasks/app_window_size_manager.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../shared/base.dart';
import '../../shared/common_operations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Zoom in/out: ', () {
    Future<void> resetAppFlowyScaleFactor(
      WindowSizeManager windowSizeManager,
    ) async {
      appflowyScaleFactor = 1.0;
      await windowSizeManager.setScaleFactor(1.0);
    }

    testWidgets('Zoom in', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      double currentScaleFactor = 1.0;

      // this value can't be defined in the setUp method, because the windowSizeManager is not initialized yet.
      final windowSizeManager = WindowSizeManager();
      await resetAppFlowyScaleFactor(windowSizeManager);

      // zoom in 2 times
      for (final keycode in zoomInKeyCodes) {
        if (UniversalPlatform.isLinux &&
            keycode.logicalKey == LogicalKeyboardKey.add) {
          // Key LogicalKeyboardKey#79c9b(keyId: "0x0000002b", keyLabel: "+", debugName: "Add") not found in
          // linux keyCode map
          continue;
        }

        // test each keycode 2 times
        for (var i = 0; i < 2; i++) {
          await tester.simulateKeyEvent(
            keycode.logicalKey,
            isControlPressed: !UniversalPlatform.isMacOS,
            isMetaPressed: UniversalPlatform.isMacOS,
            // Register the physical key for the "Add" key, otherwise the test will fail and throw an error:
            //  Physical key for LogicalKeyboardKey#79c9b(keyId: "0x0000002b", keyLabel: "+", debugName: "Add")
            //  not found in known physical keys
            physicalKey: keycode.logicalKey == LogicalKeyboardKey.add
                ? PhysicalKeyboardKey.equal
                : null,
          );

          await tester.pumpAndSettle();

          currentScaleFactor += 0.1;

          final scaleFactor = await windowSizeManager.getScaleFactor();
          expect(currentScaleFactor, appflowyScaleFactor);
          expect(currentScaleFactor, scaleFactor);
        }
      }
    });

    testWidgets('Reset zoom', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      final windowSizeManager = WindowSizeManager();

      for (final keycode in resetZoomKeyCodes) {
        await tester.simulateKeyEvent(
          keycode.logicalKey,
          isControlPressed: !UniversalPlatform.isMacOS,
          isMetaPressed: UniversalPlatform.isMacOS,
        );
        await tester.pumpAndSettle();

        final scaleFactor = await windowSizeManager.getScaleFactor();
        expect(1.0, appflowyScaleFactor);
        expect(1.0, scaleFactor);
      }
    });

    testWidgets('Zoom out', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      double currentScaleFactor = 1.0;

      final windowSizeManager = WindowSizeManager();
      await resetAppFlowyScaleFactor(windowSizeManager);

      // zoom out 2 times
      for (final keycode in zoomOutKeyCodes) {
        if (UniversalPlatform.isLinux &&
            keycode.logicalKey == LogicalKeyboardKey.numpadSubtract) {
          //  Key LogicalKeyboardKey#2c39f(keyId: "0x20000022d", keyLabel: "Numpad Subtract", debugName: "Numpad
          // Subtract") not found in linux keyCode map
          continue;
        }
        // test each keycode 2 times
        for (var i = 0; i < 2; i++) {
          await tester.simulateKeyEvent(
            keycode.logicalKey,
            isControlPressed: !UniversalPlatform.isMacOS,
            isMetaPressed: UniversalPlatform.isMacOS,
          );
          await tester.pumpAndSettle();

          currentScaleFactor -= 0.1;

          final scaleFactor = await windowSizeManager.getScaleFactor();
          expect(currentScaleFactor, appflowyScaleFactor);
          expect(currentScaleFactor, scaleFactor);
        }
      }
    });
  });
}
