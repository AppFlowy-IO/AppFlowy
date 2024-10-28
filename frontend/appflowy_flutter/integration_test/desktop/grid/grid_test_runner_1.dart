import 'package:integration_test/integration_test.dart';

import 'grid_calculations_test.dart' as grid_calculations_test_runner;
import 'grid_edit_row_test.dart' as grid_edit_row_test_runner;
import 'grid_filter_and_sort_test.dart' as grid_filter_and_sort_test_runner;
import 'grid_reopen_test.dart' as grid_reopen_test_runner;
import 'grid_reorder_row_test.dart' as grid_reorder_row_test_runner;
import 'grid_row_test.dart' as grid_row_test_runner;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  grid_reopen_test_runner.main();
  grid_row_test_runner.main();
  grid_reorder_row_test_runner.main();
  grid_filter_and_sort_test_runner.main();
  grid_edit_row_test_runner.main();
  grid_calculations_test_runner.main();
  // DON'T add more tests here.
}
