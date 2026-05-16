import 'package:integration_test/integration_test.dart';

import 'desktop/board/board_test_runner.dart' as board_test_runner;
import 'desktop/first_test/first_test.dart' as first_test;
import 'desktop/grid/grid_test_runner_1.dart' as grid_test_runner_1;

Future<void> main() async {
  await runIntegration3OnDesktop();
}

Future<void> runIntegration3OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  first_test.main();

  board_test_runner.main();
  grid_test_runner_1.main();
  // DON'T add more tests here.
}
