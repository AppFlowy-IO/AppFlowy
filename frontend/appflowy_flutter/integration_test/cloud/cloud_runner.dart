import 'empty_test.dart' as empty_test;
import 'appflowy_cloud_auth_test.dart' as appflowy_cloud_auth_test;
import 'document_sync_test.dart' as document_sync_test;
import 'user_setting_sync_test.dart' as user_sync_test;

Future<void> main() async {
  empty_test.main();

  appflowy_cloud_auth_test.main();

  document_sync_test.main();

  user_sync_test.main();
}
