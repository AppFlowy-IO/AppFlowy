import 'package:integration_test/integration_test.dart';

import 'desktop/document/document_test_runner_2.dart' as document_test_runner_2;

Future<void> main() async {
  await runIntegration4OnDesktop();
}

Future<void> runIntegration4OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  document_test_runner_2.main();
}
