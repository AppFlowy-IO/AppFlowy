// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

/// The environment variables are defined in `.env` file that is located in the
/// appflowy_flutter.
///   Run `dart run build_runner build --delete-conflicting-outputs`
///   to generate the keys from the env file.
///
///   If you want to regenerate the keys, you need to run `dart run
///   build_runner clean` before running `dart run build_runner build
///    --delete-conflicting-outputs`.

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
    varName: 'SUPABASE_PG_URL',
    defaultValue: '',
  )
  static final String supabasePgURL = _Env.supabasePgURL;

  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_PG_USER',
    defaultValue: '',
  )
  static final String supabasePgUSER = _Env.supabasePgUSER;

  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_PG_PASSWORD',
    defaultValue: '',
  )
  static final String supabasePgPassword = _Env.supabasePgPassword;

  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_PG_PORT',
    defaultValue: '',
  )
  static final String supabasePgPort = _Env.supabasePgPort;
}

bool get isSupabaseEnable =>
    Env.supabaseUrl.isNotEmpty &&
    Env.supabaseAnonKey.isNotEmpty &&
    Env.supabaseKey.isNotEmpty &&
    Env.supabaseJwtSecret.isNotEmpty &&
    Env.supabasePgURL.isNotEmpty &&
    Env.supabasePgUSER.isNotEmpty &&
    Env.supabasePgPassword.isNotEmpty &&
    Env.supabasePgPort.isNotEmpty;
