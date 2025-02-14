import 'package:integration_test/integration_test.dart';

import 'at_menu_test.dart' as at_menu;
import 'at_menu_test.dart' as at_menu_test;
import 'page_style_test.dart' as page_style_test;
import 'plus_menu_test.dart' as plus_menu_test;
import 'simple_table_test.dart' as simple_table_test;
import 'slash_menu_test.dart' as slash_menu;
import 'title_test.dart' as title_test;
import 'toolbar_test.dart' as toolbar_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Document integration tests
  title_test.main();
  page_style_test.main();
  plus_menu_test.main();
  at_menu_test.main();
  simple_table_test.main();
  toolbar_test.main();
  slash_menu.main();
  at_menu.main();
}
