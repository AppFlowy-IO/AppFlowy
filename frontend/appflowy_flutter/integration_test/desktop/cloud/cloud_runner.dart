import 'document/document_delete_block_test.dart' as document_delete_block_test;
import 'document/document_drag_block_test.dart' as document_drag_block_test;
import 'document/document_option_actions_test.dart'
    as document_option_actions_test;
import 'sidebar/sidebar_move_page_test.dart' as sidebar_move_page_test;
import 'uncategorized/anon_user_continue_test.dart' as anon_user_continue_test;
import 'uncategorized/appflowy_cloud_auth_test.dart'
    as appflowy_cloud_auth_test;
import 'uncategorized/empty_test.dart' as preset_af_cloud_env_test;
import 'uncategorized/user_setting_sync_test.dart' as user_sync_test;
import 'workspace/workspace_test_runner.dart' as workspace_test_runner;

Future<void> main() async {
  preset_af_cloud_env_test.main();
  appflowy_cloud_auth_test.main();
  user_sync_test.main();
  anon_user_continue_test.main();

  // workspace
  workspace_test_runner.startTesting();

  // document
  document_option_actions_test.main();
  document_drag_block_test.main();
  document_delete_block_test.main();

  // sidebar
  sidebar_move_page_test.main();
}
