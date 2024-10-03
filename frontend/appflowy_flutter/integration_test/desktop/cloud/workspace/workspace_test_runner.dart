import 'package:integration_test/integration_test.dart';

import 'change_name_and_icon_test.dart' as change_name_and_icon_test;
import 'collaborative_workspace_test.dart' as collaborative_workspace_test;
import 'share_menu_test.dart' as share_menu_test;
import 'workspace_settings_test.dart' as workspace_settings_test;

void startTesting() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  workspace_settings_test.main();
  share_menu_test.main();
  collaborative_workspace_test.main();
  change_name_and_icon_test.main();
}
