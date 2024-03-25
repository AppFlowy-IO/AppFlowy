import 'package:integration_test/integration_test.dart';

import 'mobile/sign_in/anonymous_sign_in_test.dart' as anonymous_sign_in_test;

Future<void> runIntegrationOnMobile() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  anonymous_sign_in_test.main();
}
