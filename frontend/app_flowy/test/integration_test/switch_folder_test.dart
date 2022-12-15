import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('customize the folder path', () {
    // testWidgets('customize folder name and path when first launch app',
    testWidgets('reset location', (tester) async {
      // customize folder
      tester.cleanLocation(path);
      tester.setLocation(path);

      await tester.initializeAppFlowy();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tapGoButton();

      // home and readme document
      expect(find.byType(HomeStack), findsOneWidget);

      // open settings and restore the location
      await tester.openSettings();
      await tester.openSettingsPage(SettingsPage.files);
      await tester.restoreLocation();

      expect(tester.defaultLocation(), tester.currentLocation());
    });
  });
}

// TODO: update folder
const path = '/Users/lucas.xu/Desktop/FFFF/CPP';
