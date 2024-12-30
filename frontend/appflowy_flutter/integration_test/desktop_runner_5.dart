import 'package:integration_test/integration_test.dart';

import 'desktop/database/database_test_runner_2.dart' as database_test_runner_2;
import 'desktop/first_test/first_test.dart' as first_test;

Future<void> main() async {
  await runIntegration5OnDesktop();
}

Future<void> runIntegration5OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  first_test.main();

  database_test_runner_2.main();
  // DON'T add more tests here.
}
