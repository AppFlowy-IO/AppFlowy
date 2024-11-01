import 'package:integration_test/integration_test.dart';

import 'database_cell_test.dart' as database_cell_test;
import 'database_field_settings_test.dart' as database_field_settings_test;
import 'database_field_test.dart' as database_field_test;
import 'database_row_page_test.dart' as database_row_page_test;
import 'database_setting_test.dart' as database_setting_test;
import 'database_share_test.dart' as database_share_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  database_cell_test.main();
  database_field_test.main();
  database_field_settings_test.main();
  database_share_test.main();
  database_row_page_test.main();
  database_setting_test.main();
  // DON'T add more tests here.
}
