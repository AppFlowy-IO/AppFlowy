import 'package:integration_test/integration_test.dart';

import 'switch_folder_test.dart' as switch_folder_test;
import 'document_test.dart' as document_test;
import 'cover_image_test.dart' as cover_image_test;
import 'share_markdown_test.dart' as share_markdown_test;
import 'import_files_test.dart' as import_files_test;
import 'document_with_database_test.dart' as document_with_database_test;
import 'database_cell_test.dart' as database_cell_test;
import 'database_field_test.dart' as database_field_test;
import 'database_share_test.dart' as database_share_test;
import 'database_row_page_test.dart' as database_row_page_test;
import 'database_row_test.dart' as database_row_test;
import 'database_setting_test.dart' as database_setting_test;
import 'database_filter_test.dart' as database_filter_test;
import 'database_view_test.dart' as database_view_test;

/// The main task runner for all integration tests in AppFlowy.
///
/// Having a single entrypoint for integration tests is necessary due to an
/// [issue caused by switching files with integration testing](https://github.com/flutter/flutter/issues/101031).
/// If flutter/flutter#101031 is resolved, this file can be removed completely.
/// Once removed, the integration_test.yaml must be updated to exclude this as
/// as the test target.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  switch_folder_test.main();
  cover_image_test.main();
  document_test.main();
  share_markdown_test.main();
  import_files_test.main();
  document_with_database_test.main();

  // Database integration tests
  database_cell_test.main();
  database_field_test.main();
  database_share_test.main();
  database_row_page_test.main();
  database_row_test.main();
  database_setting_test.main();
  database_filter_test.main();
  database_view_test.main();

  // board_test.main();
  // empty_document_test.main();
  // smart_menu_test.main();
}
