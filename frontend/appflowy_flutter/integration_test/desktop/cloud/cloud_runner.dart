import 'data_migration/data_migration_test_runner.dart'
    as data_migration_test_runner;
import 'database/database_test_runner.dart' as database_test_runner;
import 'document/document_test_runner.dart' as document_test_runner;
import 'set_env.dart' as preset_af_cloud_env_test;
import 'sidebar/sidebar_icon_test.dart' as sidebar_icon_test;
import 'sidebar/sidebar_search_test.dart' as sidebar_search_test;
import 'sidebar/sidebar_move_page_test.dart' as sidebar_move_page_test;
import 'sidebar/sidebar_rename_untitled_test.dart'
    as sidebar_rename_untitled_test;
import 'uncategorized/uncategorized_test_runner.dart'
    as uncategorized_test_runner;
import 'workspace/workspace_test_runner.dart' as workspace_test_runner;

Future<void> main() async {
  // don't remove this test, it can prevent the test from failing.
  {
    preset_af_cloud_env_test.main();
    data_migration_test_runner.main();

    // uncategorized
    uncategorized_test_runner.main();

    // workspace
    workspace_test_runner.main();
  }

  // sidebar
  // don't remove this test, it can prevent the test from failing.
  {
    preset_af_cloud_env_test.main();
    sidebar_move_page_test.main();
    sidebar_rename_untitled_test.main();
    sidebar_icon_test.main();
    sidebar_search_test.main();
  }

  // database
  // don't remove this test, it can prevent the test from failing.
  {
    preset_af_cloud_env_test.main();
    database_test_runner.main();
  }

  // document
  // don't remove this test, it can prevent the test from failing.
  {
    preset_af_cloud_env_test.main();
    document_test_runner.main();
  }
}
