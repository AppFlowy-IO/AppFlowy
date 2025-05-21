import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/home.dart';
import 'package:appflowy/mobile/presentation/notifications/mobile_notifications_screen.dart';
import 'package:appflowy/mobile/presentation/search/mobile_search_ask_ai_entrance.dart';
import 'package:appflowy/mobile/presentation/search/mobile_search_page.dart';
import 'package:appflowy/mobile/presentation/search/mobile_search_result.dart';
import 'package:appflowy/mobile/presentation/search/mobile_search_textfield.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Search test', () {
    testWidgets('tap to search page', (tester) async {
      await tester.launchInAnonymousMode();
      final searchButton = find.byFlowySvg(FlowySvgs.m_home_search_icon_m);
      await tester.tapButton(searchButton);

      ///check for UI element
      expect(find.byType(MobileSearchAskAiEntrance), findsNothing);
      expect(find.byType(MobileSearchRecentList), findsOneWidget);
      expect(find.byType(MobileSearchResultList), findsNothing);

      /// search for something
      final searchTextField = find.descendant(
        of: find.byType(MobileSearchTextfield),
        matching: find.byType(TextFormField),
      );
      final query = '$gettingStarted searching';
      await tester.enterText(searchTextField, query);
      await tester.pumpAndSettle();

      expect(find.byType(MobileSearchRecentList), findsNothing);
      expect(find.byType(MobileSearchResultList), findsOneWidget);
      expect(
        find.text(LocaleKeys.search_noResultForSearching.tr()),
        findsOneWidget,
      );

      /// clear text
      final clearButton = find.byFlowySvg(FlowySvgs.clear_s);
      await tester.tapButton(clearButton);
      expect(find.byType(MobileSearchRecentList), findsOneWidget);
      expect(find.byType(MobileSearchResultList), findsNothing);

      /// tap cancel button
      final cancelButton = find.text(LocaleKeys.button_cancel.tr());
      expect(cancelButton, findsNothing);
      await tester.enterText(searchTextField, query);
      await tester.pumpAndSettle();
      expect(cancelButton, findsOneWidget);
      await tester.tapButton(cancelButton);
      expect(cancelButton, findsNothing);
    });
  });

  testWidgets('tap to search page and back to home', (tester) async {
    await tester.launchInAnonymousMode();

    /// go to search page
    final searchButton = find.byFlowySvg(FlowySvgs.m_home_search_icon_m);
    expect(find.byType(MobileSearchScreen), findsNothing);
    await tester.tapButton(searchButton);
    expect(find.byType(MobileSearchScreen), findsOneWidget);

    /// back to home page
    final backButton = find.byFlowySvg(FlowySvgs.search_page_arrow_left_m);
    expect(backButton, findsOneWidget);
    expect(find.byType(MobileHomeScreen), findsNothing);
    await tester.tapButton(backButton);
    expect(find.byType(MobileHomeScreen), findsOneWidget);

    /// go to notification page
    final notificationButton = find.byFlowySvg(FlowySvgs.m_home_notification_m);
    expect(find.byType(MobileNotificationsScreenV2), findsNothing);
    await tester.tapButton(notificationButton);
    expect(find.byType(MobileNotificationsScreenV2), findsOneWidget);

    /// go to search page
    await tester.tapButton(searchButton);
    expect(find.byType(MobileNotificationsScreenV2), findsNothing);
    expect(find.byType(MobileSearchScreen), findsOneWidget);
    await tester.tapButton(backButton);
    expect(find.byType(MobileNotificationsScreenV2), findsOneWidget);
    expect(find.byType(MobileSearchScreen), findsNothing);
  });
}
