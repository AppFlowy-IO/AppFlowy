import 'package:integration_test/integration_test.dart';

import 'document_alignment_test.dart' as document_alignment_test;
import 'document_codeblock_paste_test.dart' as document_codeblock_paste_test;
import 'document_copy_and_paste_test.dart' as document_copy_and_paste_test;
import 'document_create_and_delete_test.dart'
    as document_create_and_delete_test;
import 'document_option_action_test.dart' as document_option_action_test;
import 'document_inline_page_reference_test.dart'
    as document_inline_page_reference_test;
import 'document_more_actions_test.dart' as document_more_actions_test;
import 'document_text_direction_test.dart' as document_text_direction_test;
import 'document_with_cover_image_test.dart' as document_with_cover_image_test;
import 'document_with_database_test.dart' as document_with_database_test;
import 'document_with_image_block_test.dart' as document_with_image_block_test;
import 'document_with_inline_math_equation_test.dart'
    as document_with_inline_math_equation_test;
import 'document_with_inline_page_test.dart' as document_with_inline_page_test;
import 'document_with_multi_image_block_test.dart'
    as document_with_multi_image_block_test;
import 'document_with_outline_block_test.dart' as document_with_outline_block;
import 'document_with_toggle_list_test.dart' as document_with_toggle_list_test;
import 'edit_document_test.dart' as document_edit_test;

void startTesting() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Document integration tests
  document_create_and_delete_test.main();
  document_edit_test.main();
  document_with_database_test.main();
  document_with_inline_page_test.main();
  document_with_inline_math_equation_test.main();
  document_with_cover_image_test.main();
  document_with_outline_block.main();
  document_with_toggle_list_test.main();
  document_copy_and_paste_test.main();
  document_codeblock_paste_test.main();
  document_alignment_test.main();
  document_text_direction_test.main();
  document_option_action_test.main();
  document_with_image_block_test.main();
  document_with_multi_image_block_test.main();
  document_inline_page_reference_test.main();
  document_more_actions_test.main();
}
