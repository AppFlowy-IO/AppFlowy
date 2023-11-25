import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/supabase_task.dart';
import 'package:appflowy/user/application/user_auth_listener.dart';
import 'package:appflowy_backend/log.dart';
import 'package:url_protocol/url_protocol.dart';

class InitAppFlowyCloudTask extends LaunchTask {
  UserAuthStateListener? _authStateListener;
  bool isLoggingOut = false;

  @override
  Future<void> initialize(LaunchContext context) async {
    if (!isAppFlowyCloudEnabled) {
      return;
    }
    _authStateListener = UserAuthStateListener();

    _authStateListener?.start(
      didSignIn: () {
        isLoggingOut = false;
      },
      onInvalidAuth: (message) async {
        Log.error(message);
        if (!isLoggingOut) {
          await runAppFlowy();
        }
      },
    );

    if (Platform.isWindows) {
      // register deep link for Windows
      registerProtocolHandler(appflowyDeepLinkSchema);
    }
  }

  @override
  Future<void> dispose() async {
    await _authStateListener?.stop();
    _authStateListener = null;
  }
}
