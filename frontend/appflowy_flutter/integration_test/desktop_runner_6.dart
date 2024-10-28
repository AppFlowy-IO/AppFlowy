import 'package:integration_test/integration_test.dart';

import 'desktop/uncategorized/uncategorized_test_runner_1.dart'
    as uncategorized_test_runner_1;

Future<void> main() async {
  await runIntegration3OnDesktop();
}

Future<void> runIntegration3OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  uncategorized_test_runner_1.main();
  // DON'T add more tests here.
}
