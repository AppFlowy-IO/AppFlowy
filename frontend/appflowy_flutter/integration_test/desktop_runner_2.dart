import 'package:integration_test/integration_test.dart';

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
import 'desktop/uncategorized/empty_test.dart' as first_test;
import 'desktop/database/database_time_field_test.dart'
    as database_time_field_test;

Future<void> main() async {
  await runIntegration2OnDesktop();
}

Future<void> runIntegration2OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // This test must be run first, otherwise the CI will fail.
  first_test.main();

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
  database_time_field_test.main();

  // DON'T add more tests here. This is the second test runner for desktop.
}
