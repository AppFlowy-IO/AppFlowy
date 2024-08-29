import 'package:appflowy_backend/log.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

    ErrorWidget.builder = (details) {
      if (kDebugMode) {
        return Container(
          width: double.infinity,
          height: 30,
          color: Colors.red,
          child: FlowyText(
            'ERROR: ${details.exceptionAsString()}',
            color: Colors.white,
          ),
        );
      }

      // hide the error widget in release mode
      return const SizedBox.shrink();
    };
  }

  @override
  Future<void> dispose() async {}
}
