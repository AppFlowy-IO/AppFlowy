import 'desktop/appearance_settings_test.dart' as appearance_test_runner;
import 'desktop/board/board_test_runner.dart' as board_test_runner;
import 'desktop/database/database_calendar_test.dart' as database_calendar_test;
import 'desktop/database/database_cell_test.dart' as database_cell_test;
import 'desktop/database/database_field_settings_test.dart'
    as database_field_settings_test;
import 'desktop/database/database_field_test.dart' as database_field_test;
import 'desktop/database/database_filter_test.dart' as database_filter_test;
import 'desktop/database/database_row_page_test.dart' as database_row_page_test;
import 'desktop/database/database_row_test.dart' as database_row_test;
import 'desktop/database/database_setting_test.dart' as database_setting_test;
import 'desktop/database/database_share_test.dart' as database_share_test;
import 'desktop/database/database_sort_test.dart' as database_sort_test;
import 'desktop/database/database_view_test.dart' as database_view_test;
import 'desktop/document/document_test_runner.dart' as document_test_runner;
import 'desktop/emoji_shortcut_test.dart' as emoji_shortcut_test;
import 'desktop/empty_test.dart' as first_test;
import 'desktop/hotkeys_test.dart' as hotkeys_test;
import 'desktop/import_files_test.dart' as import_files_test;
import 'desktop/settings/settings_runner.dart' as settings_test_runner;
import 'desktop/share_markdown_test.dart' as share_markdown_test;
import 'desktop/sidebar/sidebar_test_runner.dart' as sidebar_test_runner;
import 'desktop/switch_folder_test.dart' as switch_folder_test;
import 'desktop/tabs_test.dart' as tabs_test;

Future<void> runIntegrationOnDesktop() async {
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
  emoji_shortcut_test.main();

  // Appearance integration test
  appearance_test_runner.main();

  // User settings
  settings_test_runner.main();
}
