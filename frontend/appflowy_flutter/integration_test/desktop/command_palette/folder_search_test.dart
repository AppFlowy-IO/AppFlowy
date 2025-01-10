import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/command_palette/command_palette.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_field.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_result_tile.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
      expect(secondDocumentWidget.result.data, secondDocument);

      // Change search to "ViewOne"
      await tester.enterText(searchFieldFinder, firstDocument);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // The score should be higher for "ViewOne" thus it should be shown first
      final firstDocumentWidget = tester
          .widget(find.byType(SearchResultTile).first) as SearchResultTile;
      expect(firstDocumentWidget.result.data, firstDocument);
    });

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
}
