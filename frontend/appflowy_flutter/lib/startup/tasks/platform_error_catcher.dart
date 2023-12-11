import 'package:appflowy_backend/log.dart';
import 'package:flutter/foundation.dart';

import '../startup.dart';

class PlatformErrorCatcherTask extends LaunchTask {
  const PlatformErrorCatcherTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    // Handle platform errors not caught by Flutter.
    // Reduces the likelihood of the app crashing, and logs the error.
    // only active in non debug mode.
    if (!kDebugMode) {
      PlatformDispatcher.instance.onError = (error, stack) {
        Log.error('Uncaught platform error', error, stack);
        return true;
      };
    }
  }

  @override
  Future<void> dispose() async {}
}
