import 'package:integration_test/integration_test.dart';

import 'document_app_lifecycle_test.dart' as document_app_lifecycle_test;
import 'document_sub_page_test.dart' as document_sub_page_test;
import 'document_title_test.dart' as document_title_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Document integration tests
  document_title_test.main();
  document_sub_page_test.main();
  document_app_lifecycle_test.main();
}
