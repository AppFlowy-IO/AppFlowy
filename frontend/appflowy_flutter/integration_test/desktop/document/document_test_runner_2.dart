import 'package:integration_test/integration_test.dart';

import 'document_app_lifecycle_test.dart' as document_app_lifecycle_test;
import 'document_deletion_test.dart' as document_deletion_test;
import 'document_option_action_test.dart' as document_option_action_test;
import 'document_title_test.dart' as document_title_test;
import 'document_with_date_reminder_test.dart'
    as document_with_date_reminder_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Document integration tests
  document_title_test.main();
  // Disable subPage test temporarily, enable it in version 0.7.2
  // document_sub_page_test.main();
  document_app_lifecycle_test.main();
  document_with_date_reminder_test.main();
  document_deletion_test.main();
  document_option_action_test.main();
}
