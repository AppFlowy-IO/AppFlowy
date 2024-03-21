import 'package:integration_test/integration_test.dart';

import 'command_palette_test.dart' as command_palette_test;
import 'folder_search_test.dart' as folder_search_test;
import 'recent_history_test.dart' as recent_history_test;

void startTesting() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Command Palette integration tests
  command_palette_test.main();
  folder_search_test.main();
  recent_history_test.main();
}
