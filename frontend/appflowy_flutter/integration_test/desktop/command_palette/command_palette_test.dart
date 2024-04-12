import 'package:appflowy/workspace/presentation/command_palette/command_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
}
