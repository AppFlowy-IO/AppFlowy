import 'package:appflowy/core/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../startup.dart';

class InitSupabaseTask extends LaunchTask {
  const InitSupabaseTask({
    required this.url,
    required this.anonKey,
    required this.jwtSecret,
  });

  final String url;
  final String anonKey;
  final String jwtSecret;

  @override
  Future<void> initialize(LaunchContext context) async {
    assert(url.isNotEmpty && anonKey.isNotEmpty);
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    await Config.setSupabaseConfig(
      url: url,
      key: anonKey,
      secret: jwtSecret,
    );
  }
}
