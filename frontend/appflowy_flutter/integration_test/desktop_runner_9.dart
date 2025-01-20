import 'package:integration_test/integration_test.dart';

import 'desktop/database/database_icon_test.dart' as database_icon_test;
import 'desktop/first_test/first_test.dart' as first_test;
import 'desktop/uncategorized/code_block_language_selector_test.dart'
    as code_language_selector;
import 'desktop/uncategorized/tabs_test.dart' as tabs_test;

Future<void> main() async {
  await runIntegration9OnDesktop();
}

Future<void> runIntegration9OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  first_test.main();
  tabs_test.main();
  code_language_selector.main();
  database_icon_test.main();
}
