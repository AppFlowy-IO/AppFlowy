import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-config/entities.pb.dart';

class Config {
  static Future<void> setSupabaseConfig({
    required String url,
    required String anonKey,
    required String key,
    required String secret,
    required String pgUrl,
    required String pgUser,
    required String pgPassword,
    required String pgPort,
  }) async {
    final postgresConfig = PostgresConfigurationPB.create()
      ..url = pgUrl
      ..userName = pgUser
      ..password = pgPassword
      ..port = int.parse(pgPort);

    await ConfigEventSetSupabaseConfig(
      SupabaseConfigPB.create()
        ..supabaseUrl = url
        ..key = key
        ..anonKey = anonKey
        ..jwtSecret = secret
        ..postgresConfig = postgresConfig,
    ).send();
  }
}
