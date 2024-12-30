import 'package:integration_test/integration_test.dart';

import 'desktop/document/document_test_runner_1.dart' as document_test_runner_1;
import 'desktop/uncategorized/switch_folder_test.dart' as switch_folder_test;

Future<void> main() async {
  await runIntegration1OnDesktop();
}

Future<void> runIntegration1OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  switch_folder_test.main();
  document_test_runner_1.main();
  // DON'T add more tests here.
}
