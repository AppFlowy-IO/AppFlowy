import 'package:integration_test/integration_test.dart';

import 'board_add_row_test.dart' as board_add_row_test;
import 'board_group_test.dart' as board_group_test;
import 'board_row_test.dart' as board_row_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Board integration tests
  board_row_test.main();
  board_add_row_test.main();
  board_group_test.main();
}
