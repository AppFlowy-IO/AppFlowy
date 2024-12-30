import 'package:integration_test/integration_test.dart';

import 'sidebar_favorites_test.dart' as sidebar_favorite_test;
import 'sidebar_icon_test.dart' as sidebar_icon_test;
import 'sidebar_test.dart' as sidebar_test;
import 'sidebar_view_item_test.dart' as sidebar_view_item_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Sidebar integration tests
  sidebar_test.main();
  // sidebar_expanded_test.main();
  sidebar_favorite_test.main();
  sidebar_icon_test.main();
  sidebar_view_item_test.main();
}
