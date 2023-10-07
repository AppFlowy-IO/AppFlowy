// lib/env/env.dart
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
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
    varName: 'CLOUD_TYPE',
    defaultValue: '0',
  )
  static final int cloudType = _Env.cloudType;

  /// AppFlowy Cloud Configuration
  @EnviedField(
    obfuscate: true,
    varName: 'APPFLOWY_CLOUD_BASE_URL',
    defaultValue: '',
  )
  static final String afCloudBaseUrl = _Env.afCloudBaseUrl;

  @EnviedField(
    obfuscate: true,
    varName: 'APPFLOWY_CLOUD_WS_BASE_URL',
    defaultValue: '',
  )
  static final String afCloudWSBaseUrl = _Env.afCloudWSBaseUrl;

  @EnviedField(
    obfuscate: true,
    varName: 'APPFLOWY_CLOUD_GOTRUE_URL',
    defaultValue: '',
  )
  static final String afCloudGoTrueUrl = _Env.afCloudGoTrueUrl;

  // Supabase Configuration:
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
}

bool get isCloudEnabled {
  // Only enable supabase in release and develop mode.
  if (integrationMode().isRelease || integrationMode().isDevelop) {
    return currentCloudType().isEnabled;
  } else {
    return false;
  }
}

bool get isSupabaseEnabled {
  // Only enable supabase in release and develop mode.
  if (integrationMode().isRelease || integrationMode().isDevelop) {
    return currentCloudType() == CloudType.supabase;
  } else {
    return false;
  }
}

bool get isAppFlowyCloudEnabled {
  // Only enable appflowy cloud in release and develop mode.
  if (integrationMode().isRelease || integrationMode().isDevelop) {
    return currentCloudType() == CloudType.appflowyCloud;
  } else {
    return false;
  }
}

enum CloudType {
  unknown,
  supabase,
  appflowyCloud;

  bool get isEnabled => this != CloudType.unknown;
}

CloudType currentCloudType() {
  final value = Env.cloudType;
  if (value == 1) {
    if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
      Log.error("Supabase is not configured");
      return CloudType.unknown;
    } else {
      return CloudType.supabase;
    }
  }

  if (value == 2) {
    if (Env.afCloudBaseUrl.isEmpty || Env.afCloudWSBaseUrl.isEmpty) {
      Log.error("AppFlowy cloud is not configured");
      return CloudType.unknown;
    } else {
      return CloudType.appflowyCloud;
    }
  }

  return CloudType.unknown;
}
