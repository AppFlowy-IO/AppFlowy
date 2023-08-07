import 'dart:async';
import 'dart:io';

import 'package:appflowy/env/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_protocol/url_protocol.dart';
import '../startup.dart';

// ONLY supports in macOS and Windows now.
//
// If you need to update the schema, please update the following files:
// - appflowy_flutter/macos/Runner/Info.plist (macOS)
// - the callback url in Supabase dashboard
const appflowyDeepLinkSchema = 'appflowy-flutter';
const supabaseLoginCallback = '$appflowyDeepLinkSchema://login-callback';

bool isSupabaseInitialized = false;

class InitSupabaseTask extends LaunchTask {
  @override
  Future<void> initialize(LaunchContext context) async {
    if (!isSupabaseEnabled) {
      return;
    }

    if (isSupabaseInitialized) {
      return;
    }

    // register deep link for Windows
    if (Platform.isWindows) {
      registerProtocolHandler(appflowyDeepLinkSchema);
    }

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      debug: true,
    );

    isSupabaseInitialized = true;
  }
}
