import 'package:integration_test/integration_test.dart';

import 'notifications_settings_test.dart' as notifications_settings_test;
import 'settings_billing_test.dart' as settings_billing_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  notifications_settings_test.main();
  settings_billing_test.main();
}
