import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-config/entities.pb.dart';

class Config {
  static Future<void> setSupabaseConfig({
    required String url,
    required String anonKey,
    required String key,
    required String secret,
  }) async {
    await ConfigEventSetSupabaseConfig(
      SupabaseConfigPB.create()
        ..supabaseUrl = url
        ..key = key
        ..anonKey = anonKey
        ..jwtSecret = secret,
    ).send();
  }

  static Future<void> setSupabaseCollabPluginConfig({
    required String url,
    required String key,
    required String jwtSecret,
    required String collabTable,
  }) async {
    final payload = CollabPluginConfigPB.create();
    final collabTableConfig = CollabTableConfigPB.create()
      ..tableName = collabTable;

    payload.supabaseConfig = SupabaseDBConfigPB.create()
      ..supabaseUrl = url
      ..key = key
      ..jwtSecret = jwtSecret
      ..collabTableConfig = collabTableConfig;

    await ConfigEventSetCollabPluginConfig(payload).send();
  }
}
