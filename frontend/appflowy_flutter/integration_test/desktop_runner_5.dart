import 'package:integration_test/integration_test.dart';

import 'desktop/database/database_test_runner_2.dart' as database_test_runner_2;

Future<void> main() async {
  await runIntegration5OnDesktop();
}

Future<void> runIntegration5OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  database_test_runner_2.main();
  // DON'T add more tests here. This is the second test runner for desktop.
}
