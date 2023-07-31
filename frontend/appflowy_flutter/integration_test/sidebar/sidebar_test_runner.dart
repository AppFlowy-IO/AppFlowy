import 'package:integration_test/integration_test.dart';

import 'sidebar_test.dart' as sidebar_test;

void startTesting() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Sidebar integration tests
  sidebar_test.main();
}
