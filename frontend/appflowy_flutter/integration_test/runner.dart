import 'package:integration_test/integration_test.dart';

import 'board_test.dart' as board_test;
import 'switch_folder_test.dart' as switch_folder_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  switch_folder_test.main();
  board_test.main();
}
