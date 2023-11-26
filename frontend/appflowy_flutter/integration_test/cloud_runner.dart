import 'package:integration_test/integration_test.dart';

import 'auth/appflowy_cloud_auth_test.dart' as appflowy_cloud_auth_test;
import 'empty_test.dart' as first_test;

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // This test must be run first, otherwise the CI will fail.
  first_test.main();

  appflowy_cloud_auth_test.main();
}
