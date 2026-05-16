import 'package:integration_test/integration_test.dart';

import 'database_image_test.dart' as database_image_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  database_image_test.main();
}
