import 'package:appflowy/workspace/presentation/home/menu/app/section/item.dart';
import 'package:appflowy/workspace/presentation/home/tabs/flowy_tab.dart';
import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

import 'util/base.dart';
import 'util/common_operations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tabs', () {
    testWidgets('Open AppFlowy and open/navigate multiple tabs',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      expect(
        find.descendant(
          of: find.byType(TabsManager),
          matching: find.byType(TabBar),
        ),
        findsNothing,
      );

      await tester.tapAddButton();
      await tester.tapCreateCalendarButton();
      await tester.hoverOnPageName('Untitled');
      await tester.renamePage('Calendar');

      await tester.tapAddButton();
      await tester.tapCreateDocumentButton();
      await tester.hoverOnPageName('Untitled');
      await tester.renamePage('Document');

      // Navigate current view to "Read me" document again
      await tester.tapButtonWithName('Read me');

      /// Open second menu item in a new tab
      await tester.hoverOnPageName('Calendar');
      await tester.tap(find.byType(ViewDisclosureButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.disclosureAction_openNewTab.tr()));
      await tester.pumpAndSettle();

      /// Open third menu item in a new tab
      await tester.hoverOnPageName('Document');
      await tester.tap(find.byType(ViewDisclosureButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text(LocaleKeys.disclosureAction_openNewTab.tr()));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(TabsManager),
          matching: find.byType(TabBar),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: find.byType(TabBar),
          matching: find.byType(FlowyTab),
        ),
        findsNWidgets(3),
      );

      /// Navigate to the first tab
      await tester.tap(
        find.descendant(
          of: find.byType(FlowyTab),
          matching: find.text('Read me'),
        ),
      );
    });
  });
}
