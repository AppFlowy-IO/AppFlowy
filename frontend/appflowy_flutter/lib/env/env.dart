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
  static final String supabaseUrl = _Env.supabaseUrl;
  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_ANON_KEY',
    defaultValue: '',
  )
  static final String supabaseAnonKey = _Env.supabaseAnonKey;
  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_KEY',
    defaultValue: '',
  )
  static final String supabaseKey = _Env.supabaseKey;
  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_JWT_SECRET',
    defaultValue: '',
  )
  static final String supabaseJwtSecret = _Env.supabaseJwtSecret;

  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_COLLAB_TABLE',
    defaultValue: '',
  )
  static final String supabaseCollabTable = _Env.supabaseCollabTable;
}

bool get isSupabaseEnable =>
    Env.supabaseUrl.isNotEmpty &&
    Env.supabaseAnonKey.isNotEmpty &&
    Env.supabaseKey.isNotEmpty &&
    Env.supabaseJwtSecret.isNotEmpty;
