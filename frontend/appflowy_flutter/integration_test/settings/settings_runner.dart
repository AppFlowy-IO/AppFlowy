import 'package:integration_test/integration_test.dart';

import 'notifications_settings_test.dart' as notifications_settings_test;
import 'user_language_test.dart' as user_language_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  notifications_settings_test.main();
  user_language_test.main();
}
