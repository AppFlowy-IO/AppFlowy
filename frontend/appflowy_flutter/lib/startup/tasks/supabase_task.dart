import 'package:supabase_flutter/supabase_flutter.dart';

import '../startup.dart';

// TODO: inject these values from a config file
const supabaseUrl = '';
const anonKey = '';

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
