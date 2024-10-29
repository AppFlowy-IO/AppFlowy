import 'package:integration_test/integration_test.dart';

import 'document_inline_page_reference_test.dart'
    as document_inline_page_reference_test;
import 'document_more_actions_test.dart' as document_more_actions_test;
import 'document_shortcuts_test.dart' as document_shortcuts_test;
import 'document_with_file_test.dart' as document_with_file_test;
import 'document_with_image_block_test.dart' as document_with_image_block_test;
import 'document_with_multi_image_block_test.dart'
    as document_with_multi_image_block_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Document integration tests
  document_with_image_block_test.main();
  document_with_multi_image_block_test.main();
  document_inline_page_reference_test.main();
  document_more_actions_test.main();
  document_with_file_test.main();
  document_shortcuts_test.main();

  // Disable subPage test temporarily, enable it in version 0.7.2
  // document_sub_page_test.main();
}
