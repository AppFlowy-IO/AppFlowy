import 'dart:convert';
import 'dart:math';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/workspace/presentation/command_palette/command_palette.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_field.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_result_tile.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  setUpAll(() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Folder Search', () {
    testWidgets('Search for views', (tester) async {
      const firstDocument = "ViewOne";
      const secondDocument = "ViewOna";

      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(name: firstDocument);
      await tester.createNewPageWithNameUnderParent(name: secondDocument);

      await tester.toggleCommandPalette();
      expect(find.byType(CommandPaletteModal), findsOneWidget);

      final searchFieldFinder = find.descendant(
        of: find.byType(SearchField),
        matching: find.byType(FlowyTextField),
      );

      await tester.enterText(searchFieldFinder, secondDocument);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Expect two search results "ViewOna" and "ViewOne" (Distance 1 to ViewOna)
      expect(find.byType(SearchResultTile), findsNWidgets(2));

      // The score should be higher for "ViewOna" thus it should be shown first
      final secondDocumentWidget = tester
          .widget(find.byType(SearchResultTile).first) as SearchResultTile;
      expect(secondDocumentWidget.item.data, secondDocument);

      // Change search to "ViewOne"
      await tester.enterText(searchFieldFinder, firstDocument);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // The score should be higher for "ViewOne" thus it should be shown first
      final firstDocumentWidget = tester.widget(
        find.byType(SearchResultTile).first,
      ) as SearchResultTile;
      expect(firstDocumentWidget.item.data, firstDocument);
    });

    testWidgets('Displaying icons in search results', (tester) async {
      final randomValue = Random().nextInt(10000) + 10000;
      final pageNames = ['First Page-$randomValue', 'Second Page-$randomValue'];

      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      final emojiIconData = await tester.loadIcon();

      /// create two pages
      for (final pageName in pageNames) {
        await tester.createNewPageWithNameUnderParent(name: pageName);
        await tester.updatePageIconInTitleBarByName(
          name: pageName,
          layout: ViewLayoutPB.Document,
          icon: emojiIconData,
        );
      }

      await tester.toggleCommandPalette();

      /// search for `Page`
      final searchFieldFinder = find.descendant(
        of: find.byType(SearchField),
        matching: find.byType(FlowyTextField),
      );
      await tester.enterText(searchFieldFinder, 'Page-$randomValue');
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(find.byType(SearchResultTile), findsNWidgets(2));

      /// check results
      final svgs = find.descendant(
        of: find.byType(SearchResultTile),
        matching: find.byType(FlowySvg),
      );
      expect(svgs, findsNWidgets(2));

      final firstSvg = svgs.first.evaluate().first.widget as FlowySvg,
          lastSvg = svgs.last.evaluate().first.widget as FlowySvg;
      final iconData = IconsData.fromJson(jsonDecode(emojiIconData.emoji));

      /// icon displayed correctly
      expect(firstSvg.svgString, iconData.svgString);
      expect(lastSvg.svgString, iconData.svgString);

      testWidgets('select the content in document and search', (tester) async {
        const firstDocument = ''; // empty document

        await tester.initializeAppFlowy();
        await tester.tapAnonymousSignInButton();

        await tester.createNewPageWithNameUnderParent(name: firstDocument);
        await tester.editor.updateSelection(
          Selection(
            start: Position(
              path: [0],
            ),
            end: Position(
              path: [0],
              offset: 10,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(FloatingToolbar),
          findsOneWidget,
        );

        await tester.toggleCommandPalette();
        expect(find.byType(CommandPaletteModal), findsOneWidget);

        expect(
          find.text(LocaleKeys.menuAppHeader_defaultNewPageName.tr()),
          findsOneWidget,
        );

        expect(
          find.text(firstDocument),
          findsOneWidget,
        );
      });
    });
  });
}
