import 'dart:io';

import 'package:integration_test/integration_test.dart';

import 'desktop_runner.dart';
import 'mobile_runner.dart';

/// The main task runner for all integration tests in AppFlowy.
///
/// Having a single entrypoint for integration tests is necessary due to an
/// [issue caused by switching files with integration testing](https://github.com/flutter/flutter/issues/101031).
/// If flutter/flutter#101031 is resolved, this file can be removed completely.
/// Once removed, the integration_test.yaml must be updated to exclude this as
/// as the test target.
Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await runIntegrationOnDesktop();
  } else if (Platform.isIOS || Platform.isAndroid) {
    await runIntegrationOnMobile();
  } else {
    throw Exception('Unsupported platform');
  }
}
