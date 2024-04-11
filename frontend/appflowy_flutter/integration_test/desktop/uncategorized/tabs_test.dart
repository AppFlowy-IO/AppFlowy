import 'dart:io';

import 'package:appflowy/workspace/presentation/home/tabs/flowy_tab.dart';
import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/base.dart';
import '../../shared/common_operations.dart';
import '../../shared/expectation.dart';
import '../../shared/keyboard.dart';

const _documentName = 'First Doc';
const _documentTwoName = 'Second Doc';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tabs', () {
    testWidgets('Open AppFlowy and open/navigate/close tabs', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      expect(
        find.descendant(
          of: find.byType(TabsManager),
          matching: find.byType(TabBar),
        ),
        findsNothing,
      );

      await tester.createNewPageWithNameUnderParent(name: _documentName);

      await tester.createNewPageWithNameUnderParent(name: _documentTwoName);

      /// Open second menu item in a new tab
      await tester.openAppInNewTab(gettingStarted, ViewLayoutPB.Document);

      /// Open third menu item in a new tab
      await tester.openAppInNewTab(_documentName, ViewLayoutPB.Document);

      expect(
        find.descendant(
          of: find.byType(TabBar),
          matching: find.byType(FlowyTab),
        ),
        findsNWidgets(3),
      );

      /// Navigate to the second tab
      await tester.tap(
        find.descendant(
          of: find.byType(FlowyTab),
          matching: find.text(gettingStarted),
        ),
      );

      /// Close tab by shortcut
      await FlowyTestKeyboard.simulateKeyDownEvent(
        [
          Platform.isMacOS
              ? LogicalKeyboardKey.meta
              : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyW,
        ],
        tester: tester,
      );

      expect(
        find.descendant(
          of: find.byType(TabBar),
          matching: find.byType(FlowyTab),
        ),
        findsNWidgets(2),
      );
    });
  });
}
