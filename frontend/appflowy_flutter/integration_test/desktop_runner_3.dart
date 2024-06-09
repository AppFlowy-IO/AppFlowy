import 'package:integration_test/integration_test.dart';

import 'desktop/board/board_test_runner.dart' as board_test_runner;
import 'desktop/settings/settings_runner.dart' as settings_test_runner;
import 'desktop/sidebar/sidebar_test_runner.dart' as sidebar_test_runner;
import 'desktop/uncategorized/emoji_shortcut_test.dart' as emoji_shortcut_test;
import 'desktop/uncategorized/empty_test.dart' as first_test;
import 'desktop/uncategorized/hotkeys_test.dart' as hotkeys_test;
import 'desktop/uncategorized/import_files_test.dart' as import_files_test;
import 'desktop/uncategorized/share_markdown_test.dart' as share_markdown_test;
import 'desktop/uncategorized/tabs_test.dart' as tabs_test;

Future<void> main() async {
  await runIntegration3OnDesktop();
}

Future<void> runIntegration3OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // This test must be run first, otherwise the CI will fail.
  first_test.main();

  hotkeys_test.main();
  emoji_shortcut_test.main();
  hotkeys_test.main();
  emoji_shortcut_test.main();
  settings_test_runner.main();
  share_markdown_test.main();
  import_files_test.main();
  sidebar_test_runner.main();
  board_test_runner.main();
  tabs_test.main();
}
