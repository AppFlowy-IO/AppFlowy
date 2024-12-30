import 'package:appflowy/mobile/presentation/home/home.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('anonymous sign in on mobile:', () {
    testWidgets('anon user and then sign in', (tester) async {
      await tester.launchInAnonymousMode();

      // expect to see the home page
      expect(find.byType(MobileHomeScreen), findsOneWidget);
    });
  });
}
