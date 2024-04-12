import 'package:appflowy/workspace/presentation/command_palette/command_palette.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_field.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_result_tile.dart';
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
  });
}
