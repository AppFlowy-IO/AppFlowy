import 'package:integration_test/integration_test.dart';

import 'document_copy_link_to_block_test.dart'
    as document_copy_link_to_block_test;
import 'document_option_actions_test.dart' as document_option_actions_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  document_option_actions_test.main();
  document_copy_link_to_block_test.main();
}
