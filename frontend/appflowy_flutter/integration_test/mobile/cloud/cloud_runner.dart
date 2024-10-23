import 'document/publish_test.dart' as publish_test;
import 'document/share_link_test.dart' as share_link_test;
import 'workspace/workspace_operations_test.dart' as workspace_operations_test;

Future<void> main() async {
  workspace_operations_test.main();
  share_link_test.main();
  publish_test.main();
}
