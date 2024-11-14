import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/tabs/flowy_tab.dart';
import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/keyboard.dart';
import '../../shared/util.dart';

const _documentName = 'First Doc';
const _documentTwoName = 'Second Doc';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tabs', () {
    testWidgets('open/navigate/close tabs', (tester) async {
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
          of: find.byType(TabsManager),
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

    testWidgets('right click show tab menu, close others', (tester) async {
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
          of: find.byType(TabsManager),
          matching: find.byType(FlowyTab),
        ),
        findsNWidgets(3),
      );

      /// Right click on second tab
      await tester.tap(
        buttons: kSecondaryButton,
        find.descendant(
          of: find.byType(FlowyTab),
          matching: find.text(gettingStarted),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabMenu), findsOneWidget);

      final firstTabFinder = find.descendant(
        of: find.byType(FlowyTab),
        matching: find.text(_documentTwoName),
      );
      final secondTabFinder = find.descendant(
        of: find.byType(FlowyTab),
        matching: find.text(gettingStarted),
      );
      final thirdTabFinder = find.descendant(
        of: find.byType(FlowyTab),
        matching: find.text(_documentName),
      );

      expect(firstTabFinder, findsOneWidget);
      expect(secondTabFinder, findsOneWidget);
      expect(thirdTabFinder, findsOneWidget);

      // Close other tabs than the second item
      await tester.tap(find.text(LocaleKeys.tabMenu_closeOthers.tr()));
      await tester.pumpAndSettle();

      // We expect to not find any tabs
      expect(firstTabFinder, findsNothing);
      expect(secondTabFinder, findsNothing);
      expect(thirdTabFinder, findsNothing);

      // Expect second tab to be current page (current page has breadcrumb, cover title,
      //  and in this case view name in sidebar)
      expect(find.text(gettingStarted), findsNWidgets(3));
    });
  });
}
