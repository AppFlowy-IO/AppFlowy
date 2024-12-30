import 'package:integration_test/integration_test.dart';

import 'document_ai_writer_test.dart' as document_ai_writer_test;
import 'document_copy_link_to_block_test.dart'
    as document_copy_link_to_block_test;
import 'document_option_actions_test.dart' as document_option_actions_test;
import 'document_publish_test.dart' as document_publish_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  document_option_actions_test.main();
  document_copy_link_to_block_test.main();
  document_publish_test.main();
  document_ai_writer_test.main();
}
