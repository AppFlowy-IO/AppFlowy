import 'package:integration_test/integration_test.dart';

import 'notifications_settings_test.dart' as notifications_settings_test;
import 'settings_billing_test.dart' as settings_billing_test;
import 'shortcuts_settings_test.dart' as shortcuts_settings_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  notifications_settings_test.main();
  settings_billing_test.main();
  shortcuts_settings_test.main();
}
