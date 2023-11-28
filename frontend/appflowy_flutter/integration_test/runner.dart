import 'package:integration_test/integration_test.dart';

import 'appearance_settings_test.dart' as appearance_test_runner;
import 'board/board_test_runner.dart' as board_test_runner;
import 'database/database_calendar_test.dart' as database_calendar_test;
import 'database/database_cell_test.dart' as database_cell_test;
import 'database/database_field_settings_test.dart'
    as database_field_settings_test;
import 'database/database_field_test.dart' as database_field_test;
import 'database/database_filter_test.dart' as database_filter_test;
import 'database/database_row_page_test.dart' as database_row_page_test;
import 'database/database_row_test.dart' as database_row_test;
import 'database/database_setting_test.dart' as database_setting_test;
import 'database/database_share_test.dart' as database_share_test;
import 'database/database_sort_test.dart' as database_sort_test;
import 'database/database_view_test.dart' as database_view_test;
import 'document/document_test_runner.dart' as document_test_runner;
import 'empty_test.dart' as first_test;
import 'hotkeys_test.dart' as hotkeys_test;
import 'import_files_test.dart' as import_files_test;
import 'settings/settings_runner.dart' as settings_test_runner;
import 'share_markdown_test.dart' as share_markdown_test;
import 'sidebar/sidebar_test_runner.dart' as sidebar_test_runner;
import 'switch_folder_test.dart' as switch_folder_test;
import 'tabs_test.dart' as tabs_test;
// import 'auth/supabase_auth_test.dart' as supabase_auth_test_runner;

/// The main task runner for all integration tests in AppFlowy.
///
/// Having a single entrypoint for integration tests is necessary due to an
/// [issue caused by switching files with integration testing](https://github.com/flutter/flutter/issues/101031).
/// If flutter/flutter#101031 is resolved, this file can be removed completely.
/// Once removed, the integration_test.yaml must be updated to exclude this as
/// as the test target.
Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // This test must be run first, otherwise the CI will fail.
  first_test.main();

  switch_folder_test.main();
  share_markdown_test.main();
  import_files_test.main();

  // Document integration tests
  document_test_runner.startTesting();

  // Sidebar integration tests
  sidebar_test_runner.startTesting();

  // Board integration test
  board_test_runner.startTesting();

  // Database integration tests
  database_cell_test.main();
  database_field_test.main();
  database_field_settings_test.main();
  database_share_test.main();
  database_row_page_test.main();
  database_row_test.main();
  database_setting_test.main();
  database_filter_test.main();
  database_sort_test.main();
  database_view_test.main();
  database_calendar_test.main();

  // Tabs
  tabs_test.main();

  // Others
  hotkeys_test.main();

  // Appearance integration test
  appearance_test_runner.main();

  // User settings
  settings_test_runner.main();

  // board_test.main();
  // empty_document_test.main();
  // smart_menu_test.main();
}
