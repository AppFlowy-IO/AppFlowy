import 'package:integration_test/integration_test.dart';

import 'desktop/database/database_test_runner_1.dart' as database_test_runner_1;
import 'desktop/first_test/first_test.dart' as first_test;

Future<void> main() async {
  await runIntegration2OnDesktop();
}

Future<void> runIntegration2OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  first_test.main();

  database_test_runner_1.main();
  // DON'T add more tests here. This is the second test runner for desktop.
}
