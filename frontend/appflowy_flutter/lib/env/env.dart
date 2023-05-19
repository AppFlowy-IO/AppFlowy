// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL', defaultValue: '')
  static const supabaseUrl = _Env.supabaseUrl;
  @EnviedField(varName: 'SUPABASE_ANON_KEY', defaultValue: '')
  static const supabaseAnonKey = _Env.supabaseAnonKey;
  @EnviedField(varName: 'SUPABASE_KEY', defaultValue: '')
  static const supabaseKey = _Env.supabaseKey;
  @EnviedField(varName: 'SUPABASE_JWT_SECRET', defaultValue: '')
  static const supabaseJwtSecret = _Env.supabaseJwtSecret;
}
