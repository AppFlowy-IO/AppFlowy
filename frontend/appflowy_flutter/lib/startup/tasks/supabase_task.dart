import 'dart:async';
import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/user/application/supabase_realtime.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
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

const hiveBoxName = 'appflowy_supabase_authentication';

// Used to store the session of the supabase in case of the user switch the different folder.
Supabase? supabase;
SupabaseRealtimeService? realtimeService;

class InitSupabaseTask extends LaunchTask {
  @override
  Future<void> initialize(LaunchContext context) async {
    if (!isSupabaseEnabled) {
      return;
    }

    supabase?.dispose();
    supabase = null;
    final initializedSupabase = await Supabase.initialize(
      url: getIt<AppFlowyCloudSharedEnv>().supabaseConfig.url,
      anonKey: getIt<AppFlowyCloudSharedEnv>().supabaseConfig.anon_key,
      debug: kDebugMode,
      localStorage: const SupabaseLocalStorage(),
    );

    if (realtimeService != null) {
      await realtimeService?.dispose();
      realtimeService = null;
    }
    realtimeService = SupabaseRealtimeService(supabase: initializedSupabase);

    supabase = initializedSupabase;

    if (Platform.isWindows) {
      // register deep link for Windows
      registerProtocolHandler(appflowyDeepLinkSchema);
    }
  }

  @override
  Future<void> dispose() async {
    await realtimeService?.dispose();
    realtimeService = null;
    supabase?.dispose();
    supabase = null;
  }
}

/// customize the supabase auth storage
///
/// We don't use the default one because it always save the session in the document directory.
/// When we switch to the different folder, the session still exists.
class SupabaseLocalStorage extends LocalStorage {
  const SupabaseLocalStorage()
      : super(
          initialize: _initialize,
          hasAccessToken: _hasAccessToken,
          accessToken: _accessToken,
          removePersistedSession: _removePersistedSession,
          persistSession: _persistSession,
        );

  static Future<void> _initialize() async {
    HiveCipher? encryptionCipher;

    // customize the path for Hive
    final path = await getIt<ApplicationDataStorage>().getPath();
    Hive.init(p.join(path, 'supabase_auth'));
    await Hive.openBox(
      hiveBoxName,
      encryptionCipher: encryptionCipher,
    );
  }

  static Future<bool> _hasAccessToken() {
    return Future.value(
      Hive.box(hiveBoxName).containsKey(
        supabasePersistSessionKey,
      ),
    );
  }

  static Future<String?> _accessToken() {
    return Future.value(
      Hive.box(hiveBoxName).get(supabasePersistSessionKey) as String?,
    );
  }

  static Future<void> _removePersistedSession() {
    return Hive.box(hiveBoxName).delete(supabasePersistSessionKey);
  }

  static Future<void> _persistSession(String persistSessionString) {
    return Hive.box(hiveBoxName).put(
      supabasePersistSessionKey,
      persistSessionString,
    );
  }
}
