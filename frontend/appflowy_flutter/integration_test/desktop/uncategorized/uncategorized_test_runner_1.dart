import 'package:integration_test/integration_test.dart';

import 'emoji_shortcut_test.dart' as emoji_shortcut_test;
import 'empty_test.dart' as first_test;
import 'hotkeys_test.dart' as hotkeys_test;
import 'import_files_test.dart' as import_files_test;
import 'share_markdown_test.dart' as share_markdown_test;
import 'tabs_test.dart' as tabs_test;
import 'zoom_in_out_test.dart' as zoom_in_out_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // This test must be run first, otherwise the CI will fail.
  first_test.main();
  hotkeys_test.main();
  emoji_shortcut_test.main();
  hotkeys_test.main();
  emoji_shortcut_test.main();
  share_markdown_test.main();
  import_files_test.main();
  tabs_test.main();
  zoom_in_out_test.main();
  // DON'T add more tests here.
}
