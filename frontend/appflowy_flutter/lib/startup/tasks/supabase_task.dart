import 'package:appflowy/core/config/config.dart';
import 'package:appflowy/env/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../startup.dart';

bool isSupabaseInitialized = false;

class InitSupabaseTask extends LaunchTask {
  @override
  Future<void> initialize(LaunchContext context) async {
    if (!isSupabaseEnable) {
      return;
    }

    if (isSupabaseInitialized) {
      return;
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      debug: false,
    );

    await Config.setSupabaseConfig(
      url: Env.supabaseUrl,
      key: Env.supabaseKey,
      secret: Env.supabaseJwtSecret,
      anonKey: Env.supabaseAnonKey,
      pgPassword: Env.supabasePgPassword,
      pgPort: Env.supabasePgPort,
      pgUrl: Env.supabasePgURL,
      pgUser: Env.supabasePgUSER,
    );
    isSupabaseInitialized = true;
  }
}
