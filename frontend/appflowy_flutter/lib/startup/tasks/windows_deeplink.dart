import 'dart:io';

import 'package:url_protocol/url_protocol.dart';

import '../startup.dart';

/// Register the deep link for Windows platform.
///
/// This task is ONLY for Windows platform, because the `url_protocol` package is ONLY supported on Windows platform.
///
/// https://pub.dev/packages/url_protocol
/// https://pub.dev/packages/supabase_flutter
///

class WindowsDeepLink extends LaunchTask {
  @override
  Future<void> initialize(LaunchContext context) async {
    if (!Platform.isWindows) {
      return;
    }

    const deepLink = 'io.appflowy.appflowy-flutter';
    unregisterProtocolHandler(deepLink);
    registerProtocolHandler(deepLink);
  }
}
