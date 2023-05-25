// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_URL',
    defaultValue: '',
  )
  static final supabaseUrl = _Env.supabaseUrl;
  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_ANON_KEY',
    defaultValue: '',
  )
  static final supabaseAnonKey = _Env.supabaseAnonKey;
  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_KEY',
    defaultValue: '',
  )
  static final supabaseKey = _Env.supabaseKey;
  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_JWT_SECRET',
    defaultValue: '',
  )
  static final supabaseJwtSecret = _Env.supabaseJwtSecret;

  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_COLLAB_TABLE',
    defaultValue: '',
  )
  static final supabaseCollabTable = _Env.supabaseCollabTable;
}

bool get isSupabaseEnable =>
    Env.supabaseUrl.isNotEmpty &&
    Env.supabaseAnonKey.isNotEmpty &&
    Env.supabaseKey.isNotEmpty &&
    Env.supabaseJwtSecret.isNotEmpty;
