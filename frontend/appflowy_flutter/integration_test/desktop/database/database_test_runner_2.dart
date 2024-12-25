import 'package:integration_test/integration_test.dart';

import 'database_calendar_test.dart' as database_calendar_test;
import 'database_filter_test.dart' as database_filter_test;
import 'database_media_test.dart' as database_media_test;
import 'database_row_cover_test.dart' as database_row_cover_test;
import 'database_share_test.dart' as database_share_test;
import 'database_sort_test.dart' as database_sort_test;
import 'database_view_test.dart' as database_view_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  database_filter_test.main();
  database_sort_test.main();
  database_view_test.main();
  database_calendar_test.main();
  database_media_test.main();
  database_row_cover_test.main();
  database_share_test.main();
  // DON'T add more tests here.
}
