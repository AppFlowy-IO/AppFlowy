import 'package:integration_test/integration_test.dart';

import 'page_style_test.dart' as page_style_test;
import 'title_test.dart' as title_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Document integration tests
  title_test.main();
  page_style_test.main();
}
