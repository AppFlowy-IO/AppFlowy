import 'dart:io';

import 'desktop_runner_1.dart';
import 'desktop_runner_2.dart';
import 'desktop_runner_3.dart';
import 'desktop_runner_4.dart';
import 'desktop_runner_5.dart';
import 'desktop_runner_6.dart';
import 'mobile_runner.dart';

/// The main task runner for all integration tests in AppFlowy.
///
/// Having a single entrypoint for integration tests is necessary due to an
/// [issue caused by switching files with integration testing](https://github.com/flutter/flutter/issues/101031).
/// If flutter/flutter#101031 is resolved, this file can be removed completely.
/// Once removed, the integration_test.yaml must be updated to exclude this as
/// as the test target.
Future<void> main() async {
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await runIntegration1OnDesktop();
    await runIntegration2OnDesktop();
    await runIntegration3OnDesktop();
    await runIntegration4OnDesktop();
    await runIntegration5OnDesktop();
    await runIntegration6OnDesktop();
  } else if (Platform.isIOS || Platform.isAndroid) {
    await runIntegrationOnMobile();
  } else {
    throw Exception('Unsupported platform');
  }
}
