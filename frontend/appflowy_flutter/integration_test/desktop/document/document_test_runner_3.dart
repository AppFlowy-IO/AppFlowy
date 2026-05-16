import 'package:integration_test/integration_test.dart';

import 'document_alignment_test.dart' as document_alignment_test;
import 'document_codeblock_paste_test.dart' as document_codeblock_paste_test;
import 'document_copy_and_paste_test.dart' as document_copy_and_paste_test;
import 'document_text_direction_test.dart' as document_text_direction_test;
import 'document_with_outline_block_test.dart' as document_with_outline_block;
import 'document_with_toggle_list_test.dart' as document_with_toggle_list_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Document integration tests
  document_with_outline_block.main();
  document_with_toggle_list_test.main();
  document_copy_and_paste_test.main();
  document_codeblock_paste_test.main();
  document_alignment_test.main();
  document_text_direction_test.main();

  // Don't add new tests here.
}
