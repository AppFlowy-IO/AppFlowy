import 'package:integration_test/integration_test.dart';

import 'mobile/home_page/create_new_page_test.dart' as create_new_page_test;
import 'mobile/sign_in/anonymous_sign_in_test.dart' as anonymous_sign_in_test;

Future<void> runIntegrationOnMobile() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  anonymous_sign_in_test.main();
  create_new_page_test.main();
}
