import 'package:supabase_flutter/supabase_flutter.dart';

import '../startup.dart';

class InitSupabaseTask extends LaunchTask {
  const InitSupabaseTask({
    required this.url,
    required this.anonKey,
  });

  final String url;
  final String anonKey;

  @override
  Future<void> initialize(LaunchContext context) async {
    assert(url.isNotEmpty && anonKey.isNotEmpty);
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
