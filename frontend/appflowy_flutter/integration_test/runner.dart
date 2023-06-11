import 'package:integration_test/integration_test.dart';

import 'switch_folder_test.dart' as switch_folder_test;
import 'document_test.dart' as document_test;
import 'cover_image_test.dart' as cover_image_test;

/// The main task runner for all integration tests in AppFlowy.
///
/// Having a single entrypoint for integration tests is necessary due to an
/// [issue caused by switching files with integration testing](https://github.com/flutter/flutter/issues/101031).
/// If flutter/flutter#101031 is resolved, this file can be removed completely.
/// Once removed, the integration_test.yaml must be updated to exclude this as
/// as the test target.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  switch_folder_test.main();
  cover_image_test.main();
  document_test.main();
  // board_test.main();
  // empty_document_test.main();
  // smart_menu_test.main();
}
