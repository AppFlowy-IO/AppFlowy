import 'package:integration_test/integration_test.dart';

import 'notifications_settings_test.dart' as notifications_settings_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  notifications_settings_test.main();
}
