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

/// Follow the guide on https://supabase.com/docs/guides/auth/social-login/auth-google to setup the auth provider.
///
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
    varName: 'SUPABASE_JWT_SECRET',
    defaultValue: '',
  )
  static final String supabaseJwtSecret = _Env.supabaseJwtSecret;
}

bool get isSupabaseEnable => false;
    // Env.supabaseUrl.isNotEmpty &&
    // Env.supabaseAnonKey.isNotEmpty &&
    // Env.supabaseKey.isNotEmpty &&
    // Env.supabaseJwtSecret.isNotEmpty &&
    // Env.supabaseDb.isNotEmpty &&
    // Env.supabaseDbUser.isNotEmpty &&
    // Env.supabaseDbPassword.isNotEmpty &&
    // Env.supabaseDbPort.isNotEmpty;
