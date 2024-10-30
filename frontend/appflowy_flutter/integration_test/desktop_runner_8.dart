import 'package:integration_test/integration_test.dart';

import 'desktop/document/document_test_runner_4.dart' as document_test_runner_4;
import 'desktop/first_test/first_test.dart' as first_test;

Future<void> main() async {
  await runIntegration8OnDesktop();
}

Future<void> runIntegration8OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  first_test.main();

  document_test_runner_4.main();
  // DON'T add more tests here.
}
