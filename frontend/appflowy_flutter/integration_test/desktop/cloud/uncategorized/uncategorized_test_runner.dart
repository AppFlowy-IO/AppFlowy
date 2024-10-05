import 'appflowy_cloud_auth_test.dart' as appflowy_cloud_auth_test;
import 'empty_test.dart' as preset_af_cloud_env_test;
import 'user_setting_sync_test.dart' as user_sync_test;

void main() async {
  preset_af_cloud_env_test.main();
  appflowy_cloud_auth_test.main();
  user_sync_test.main();
}
