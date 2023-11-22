// lib/env/env.dart
import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:dartz/dartz.dart';
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
abstract class _Env {
  @EnviedField(
    obfuscate: true,
    varName: 'CLOUD_TYPE',
    defaultValue: '0',
  )
  static final int cloudType = __Env.cloudType;

  // Supabase Configuration:
  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_URL',
    defaultValue: '',
  )
  static final String supabaseUrl = __Env.supabaseUrl;
  @EnviedField(
    obfuscate: true,
    varName: 'SUPABASE_ANON_KEY',
    defaultValue: '',
  )
  static final String supabaseAnonKey = __Env.supabaseAnonKey;
}

bool get isCloudEnabled {
  // Only enable supabase in release and develop mode.
  if (integrationMode().isRelease || integrationMode().isDevelop) {
    return currentCloudType().isEnabled;
  } else {
    return false;
  }
}

bool get isAuthEnabled {
  // Only enable supabase in release and develop mode.
  if (integrationMode().isRelease || integrationMode().isDevelop) {
    final env = getIt<AppFlowyCloudSharedEnv>();
    return env.appflowyCloudConfig.isValid || env.supabaseConfig.isValid;
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
  final value = _Env.cloudType;
  if (value == 1) {
    if (_Env.supabaseUrl.isEmpty || _Env.supabaseAnonKey.isEmpty) {
      Log.error(
        "Supabase is not configured correctly. The values are: "
        "url: ${_Env.supabaseUrl}, anonKey: ${_Env.supabaseAnonKey}",
      );
      return CloudType.unknown;
    } else {
      return CloudType.supabase;
    }
  }

  if (value == 2) {
    // final cloudURL =
    //     getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig.base_url;
    // final wsURL =
    //     getIt<AppFlowyCloudSharedEnv>().appflowyCloudConfig.ws_base_url;

    // if (cloudURL.isEmpty || wsURL.isEmpty) {
    //   Log.error(
    //     "AppFlowy cloud is not configured correctly. The values are: "
    //     "baseUrl: ${_Env.afCloudBaseUrl}, wsBaseUrl: ${_Env.afCloudWSBaseUrl}",
    //   );
    //   return CloudType.unknown;
    // } else {
    //   return CloudType.appflowyCloud;
    // }
    return CloudType.appflowyCloud;
  }

  return CloudType.unknown;
}

Future<void> setAppFlowyCloudBaseUrl(Option<String> url) async {
  await url.fold(
    () => getIt<KeyValueStorage>().remove(KVKeys.appflowyCloudBaseURL),
    (s) => getIt<KeyValueStorage>().set(KVKeys.appflowyCloudBaseURL, s),
  );
}

/// Use getIt<AppFlowyCloudSharedEnv>() to get the shared environment.
class AppFlowyCloudSharedEnv {
  final int cloudType;
  final AppFlowyCloudConfiguration appflowyCloudConfig;
  final SupabaseConfiguration supabaseConfig;

  AppFlowyCloudSharedEnv({
    required this.appflowyCloudConfig,
    required this.supabaseConfig,
  }) : cloudType = _Env.cloudType;
}

Future<AppFlowyCloudConfiguration> getAppFlowyCloudConfig() async {
  return AppFlowyCloudConfiguration(
    base_url: await getAppFlowyCloudUrl(),
    ws_base_url: await getAppFlowyCloudWSUrl(),
    gotrue_url: await getAppFlowyCloudGotrueUrl(),
  );
}

Future<SupabaseConfiguration> getSupabaseCloudConfig() async {
  return SupabaseConfiguration(
    url: _Env.supabaseUrl,
    anon_key: _Env.supabaseAnonKey,
  );
}

Future<String> getAppFlowyCloudUrl() async {
  final result =
      await getIt<KeyValueStorage>().get(KVKeys.appflowyCloudBaseURL);
  return result.fold(
    () => "",
    (url) => url,
  );
}

Future<String> getAppFlowyCloudWSUrl() async {
  try {
    final serverUrl = await getAppFlowyCloudUrl();
    final uri = Uri.parse(serverUrl);
    final host = uri.host;
    if (uri.isScheme('HTTPS')) {
      return 'wss://$host/ws';
    } else {
      return 'ws://$host/ws';
    }
  } catch (e) {
    Log.error("Failed to get websocket url: $e");
    return "";
  }
}

Future<String> getAppFlowyCloudGotrueUrl() async {
  final serverUrl = await getAppFlowyCloudUrl();
  return "$serverUrl/gotrue";
}
