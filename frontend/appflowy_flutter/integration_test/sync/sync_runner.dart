import 'package:integration_test/integration_test.dart';

import 'document_sync_test.dart' as document_sync_test;

void startTesting() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  document_sync_test.main();
}
