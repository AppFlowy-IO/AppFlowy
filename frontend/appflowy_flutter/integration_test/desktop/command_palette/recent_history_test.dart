import 'package:appflowy/workspace/presentation/command_palette/command_palette.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/recent_view_tile.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/recent_views_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Recent History', () {
    testWidgets('Search for views', (tester) async {
      const firstDocument = "First";
      const secondDocument = "Second";

      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(name: firstDocument);
      await tester.createNewPageWithNameUnderParent(name: secondDocument);

      await tester.toggleCommandPalette();
      expect(find.byType(CommandPaletteModal), findsOneWidget);

      // Expect history list
      expect(find.byType(RecentViewsList), findsOneWidget);

      // Expect three recent history items
      expect(find.byType(RecentViewTile), findsNWidgets(3));

      // Expect the first item to be the last viewed document
      final firstDocumentWidget =
          tester.widget(find.byType(RecentViewTile).first) as RecentViewTile;
      expect(firstDocumentWidget.view.name, secondDocument);
    });
  });
}
