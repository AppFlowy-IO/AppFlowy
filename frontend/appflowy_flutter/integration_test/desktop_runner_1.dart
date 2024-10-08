import 'package:integration_test/integration_test.dart';

import 'desktop/document/document_test_runner_1.dart' as document_test_runner;
import 'desktop/uncategorized/empty_test.dart' as first_test;
import 'desktop/uncategorized/switch_folder_test.dart' as switch_folder_test;

Future<void> main() async {
  await runIntegration1OnDesktop();
}

Future<void> runIntegration1OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // This test must be run first, otherwise the CI will fail.
  first_test.main();

  switch_folder_test.main();
  document_test_runner.main();

  // DON'T add more tests here.
}
