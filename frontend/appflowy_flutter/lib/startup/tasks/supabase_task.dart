import 'dart:async';
import 'dart:io';

import 'package:appflowy/env/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_protocol/url_protocol.dart';
import 'package:app_links/app_links.dart';
import '../startup.dart';

bool isSupabaseInitialized = false;

class InitSupabaseTask extends LaunchTask {
  final applinks = AppLinks();
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
      registerProtocolHandler('appflowy-flutter');
    }

    applinks.allUriLinkStream.listen((event) {
      print(event);
    });

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      debug: true,
      // authFlowType: AuthFlowType.pkce,
    );

    isSupabaseInitialized = true;
  }
}
