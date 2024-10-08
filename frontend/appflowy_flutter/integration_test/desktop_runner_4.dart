import 'package:integration_test/integration_test.dart';

import 'desktop/document/document_test_runner_2.dart' as document_test_runner_2;
import 'desktop/uncategorized/empty_test.dart' as first_test;

Future<void> main() async {
  await runIntegration4OnDesktop();
}

Future<void> runIntegration4OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // This test must be run first, otherwise the CI will fail.
  first_test.main();

  document_test_runner_2.main();
}
