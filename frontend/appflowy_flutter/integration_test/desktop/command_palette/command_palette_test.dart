import 'package:appflowy/workspace/presentation/command_palette/command_palette.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_ask_ai_entrance.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_result_cell.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/page_preview.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/recent_views_list.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_field.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_results_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Command Palette', () {
    testWidgets('Toggle command palette', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.toggleCommandPalette();
      expect(find.byType(CommandPaletteModal), findsOneWidget);

      await tester.toggleCommandPalette();
      expect(find.byType(CommandPaletteModal), findsNothing);
    });
  });

  group('Search', () {
    testWidgets('Test for searching', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(name: 'Switch To New Page');
      await tester.pumpAndSettle();

      /// tap getting started page
      await tester.tapButton(
        find.descendant(
          of: find.byType(HomeSideBar),
          matching: find.textContaining(gettingStarted),
        ),
      );

      /// show searching page
      final searchingButton = find.text(LocaleKeys.search_label.tr());
      await tester.tapButton(searchingButton);
      final askAIButton = find.byType(SearchAskAiEntrance);
      expect(askAIButton, findsNothing);
      final recentList = find.byType(RecentViewsList);
      expect(recentList, findsOneWidget);

      /// there is [gettingStarted] in recent list
      final gettingStartedRecentCell = find.descendant(
        of: recentList,
        matching: find.textContaining(gettingStarted),
      );
      expect(gettingStartedRecentCell, findsAtLeast(1));

      /// hover to show preview
      await tester.hoverOnWidget(gettingStartedRecentCell.first);
      final pagePreview = find.byType(PagePreview);
      expect(pagePreview, findsOneWidget);
      final gettingStartedPreviewTitle = find.descendant(
        of: pagePreview,
        matching: find.textContaining(gettingStarted),
      );
      expect(gettingStartedPreviewTitle, findsOneWidget);

      /// searching for [gettingStarted]
      final searchField = find.byType(SearchField);
      final textFiled =
          find.descendant(of: searchField, matching: find.byType(TextField));
      await tester.enterText(textFiled, gettingStarted);
      await tester.pumpAndSettle(Duration(seconds: 1));

      /// there is [gettingStarted] in result list
      final resultList = find.byType(SearchResultList);
      expect(resultList, findsOneWidget);
      final resultCells = find.byType(SearchResultCell);
      expect(resultCells, findsAtLeast(1));

      /// hover to show preview
      await tester.hoverOnWidget(resultCells.first);
      expect(find.byType(PagePreview), findsOneWidget);

      /// clear search content
      final clearButton = find.byFlowySvg(FlowySvgs.search_clear_m);
      await tester.tapButton(clearButton);
      expect(find.byType(SearchResultList), findsNothing);
      expect(find.byType(RecentViewsList), findsOneWidget);
    });
  });
}
