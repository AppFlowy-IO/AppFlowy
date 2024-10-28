import 'package:integration_test/integration_test.dart';

import 'desktop/first_test/first_test.dart' as first_test;
import 'desktop/settings/settings_runner.dart' as settings_test_runner;
import 'desktop/sidebar/sidebar_test_runner.dart' as sidebar_test_runner;
import 'desktop/uncategorized/uncategorized_test_runner_1.dart'
    as uncategorized_test_runner_1;

Future<void> main() async {
  await runIntegration6OnDesktop();
}

Future<void> runIntegration6OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  first_test.main();

  settings_test_runner.main();
  sidebar_test_runner.main();
  uncategorized_test_runner_1.main();
  // DON'T add more tests here.
}
