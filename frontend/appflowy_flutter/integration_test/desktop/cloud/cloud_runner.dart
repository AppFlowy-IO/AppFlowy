import 'document/document_test_runner.dart' as document_test_runner;
import 'sidebar/sidebar_move_page_test.dart' as sidebar_move_page_test;
import 'uncategorized/uncategorized_test_runner.dart'
    as uncategorized_test_runner;
import 'workspace/workspace_test_runner.dart' as workspace_test_runner;
import 'data_migration/data_migration_test_runner.dart' as data_migration_test_runner;

Future<void> main() async {
  data_migration_test_runner.main();
  // uncategorized
  uncategorized_test_runner.main();

  // workspace
  workspace_test_runner.main();

  // document
  document_test_runner.main();

  // sidebar
  sidebar_move_page_test.main();

}
