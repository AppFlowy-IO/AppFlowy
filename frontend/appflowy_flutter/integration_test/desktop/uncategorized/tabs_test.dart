import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/tabs/flowy_tab.dart';
import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:appflowy/workspace/presentation/widgets/tab_bar_item.dart';
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

      // No tabs rendered yet
      expect(find.byType(FlowyTab), findsNothing);

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
          of: find.byType(TabsManager),
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

    testWidgets('cannot close pinned tabs', (tester) async {
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

      // Open second menu item in a new tab
      await tester.openAppInNewTab(gettingStarted, ViewLayoutPB.Document);

      // Open third menu item in a new tab
      await tester.openAppInNewTab(_documentName, ViewLayoutPB.Document);

      expect(
        find.descendant(
          of: find.byType(TabsManager),
          matching: find.byType(FlowyTab),
        ),
        findsNWidgets(3),
      );

      const firstTab = _documentTwoName;
      const secondTab = gettingStarted;
      const thirdTab = _documentName;

      expect(tester.isTabAtIndex(firstTab, 0), isTrue);
      expect(tester.isTabAtIndex(secondTab, 1), isTrue);
      expect(tester.isTabAtIndex(thirdTab, 2), isTrue);

      expect(tester.isTabPinned(gettingStarted), isFalse);

      // Right click on second tab
      await tester.openTabMenu(gettingStarted);
      expect(find.byType(TabMenu), findsOneWidget);

      // Pin second tab
      await tester.tap(find.text(LocaleKeys.tabMenu_pinTab.tr()));
      await tester.pumpAndSettle();

      expect(tester.isTabPinned(gettingStarted), isTrue);

      /// Right click on first unpinned tab (second tab)
      await tester.openTabMenu(_documentTwoName);

      // Close others
      await tester.tap(find.text(LocaleKeys.tabMenu_closeOthers.tr()));
      await tester.pumpAndSettle();

      // We expect to find 2 tabs, the first pinned tab and the second tab
      expect(find.byType(FlowyTab), findsNWidgets(2));
      expect(tester.isTabAtIndex(gettingStarted, 0), isTrue);
      expect(tester.isTabAtIndex(_documentTwoName, 1), isTrue);
    });

    testWidgets('pin/unpin tabs proper order', (tester) async {
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

      // Open second menu item in a new tab
      await tester.openAppInNewTab(gettingStarted, ViewLayoutPB.Document);

      // Open third menu item in a new tab
      await tester.openAppInNewTab(_documentName, ViewLayoutPB.Document);

      expect(
        find.descendant(
          of: find.byType(TabsManager),
          matching: find.byType(FlowyTab),
        ),
        findsNWidgets(3),
      );

      const firstTabName = _documentTwoName;
      const secondTabName = gettingStarted;
      const thirdTabName = _documentName;

      // Expect correct order
      expect(tester.isTabAtIndex(firstTabName, 0), isTrue);
      expect(tester.isTabAtIndex(secondTabName, 1), isTrue);
      expect(tester.isTabAtIndex(thirdTabName, 2), isTrue);

      // Pin second tab
      await tester.openTabMenu(secondTabName);
      await tester.tap(find.text(LocaleKeys.tabMenu_pinTab.tr()));
      await tester.pumpAndSettle();

      expect(tester.isTabPinned(secondTabName), isTrue);

      // Expect correct order
      expect(tester.isTabAtIndex(secondTabName, 0), isTrue);
      expect(tester.isTabAtIndex(firstTabName, 1), isTrue);
      expect(tester.isTabAtIndex(thirdTabName, 2), isTrue);

      // Pin new second tab (first tab)
      await tester.openTabMenu(firstTabName);
      await tester.tap(find.text(LocaleKeys.tabMenu_pinTab.tr()));
      await tester.pumpAndSettle();

      expect(tester.isTabPinned(firstTabName), isTrue);
      expect(tester.isTabPinned(secondTabName), isTrue);
      expect(tester.isTabPinned(thirdTabName), isFalse);

      expect(tester.isTabAtIndex(secondTabName, 0), isTrue);
      expect(tester.isTabAtIndex(firstTabName, 1), isTrue);
      expect(tester.isTabAtIndex(thirdTabName, 2), isTrue);

      // Unpin second tab
      await tester.openTabMenu(secondTabName);
      await tester.tap(find.text(LocaleKeys.tabMenu_unpinTab.tr()));
      await tester.pumpAndSettle();

      expect(tester.isTabPinned(firstTabName), isTrue);
      expect(tester.isTabPinned(secondTabName), isFalse);
      expect(tester.isTabPinned(thirdTabName), isFalse);

      expect(tester.isTabAtIndex(firstTabName, 0), isTrue);
      expect(tester.isTabAtIndex(secondTabName, 1), isTrue);
      expect(tester.isTabAtIndex(thirdTabName, 2), isTrue);
    });
  });
}

extension _TabsTester on WidgetTester {
  bool isTabPinned(String tabName) {
    final tabFinder = find.ancestor(
      of: find.byWidgetPredicate(
        (w) => w is ViewTabBarItem && w.view.name == tabName,
      ),
      matching: find.byType(FlowyTab),
    );

    final FlowyTab tabWidget = widget(tabFinder);
    return tabWidget.pageManager.isPinned;
  }

  bool isTabAtIndex(String tabName, int index) {
    final tabFinder = find.ancestor(
      of: find.byWidgetPredicate(
        (w) => w is ViewTabBarItem && w.view.name == tabName,
      ),
      matching: find.byType(FlowyTab),
    );

    final pluginId = (widget(tabFinder) as FlowyTab).pageManager.plugin.id;

    final pluginIds = find
        .byType(FlowyTab)
        .evaluate()
        .map((e) => (e.widget as FlowyTab).pageManager.plugin.id);

    return pluginIds.elementAt(index) == pluginId;
  }

  Future<void> openTabMenu(String tabName) async {
    await tap(
      buttons: kSecondaryButton,
      find.ancestor(
        of: find.byWidgetPredicate(
          (w) => w is ViewTabBarItem && w.view.name == tabName,
        ),
        matching: find.byType(FlowyTab),
      ),
    );
    await pumpAndSettle();
  }
}
