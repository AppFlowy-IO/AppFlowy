import 'package:integration_test/integration_test.dart';

import 'desktop/uncategorized/tabs_test.dart' as tabs_test;
import 'desktop/first_test/first_test.dart' as first_test;

Future<void> main() async {
  await runIntegration9OnDesktop();
}

Future<void> runIntegration9OnDesktop() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  first_test.main();

  tabs_test.main();
}
