import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

// This test is meaningless, just for preventing the CI from failing.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Empty', () {
    testWidgets('empty test', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();
      await tester.wait(500);
    });
  });
}
