import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:dartz/dartz.dart';

/// Sets the cloud type for the application.
///
/// This method updates the cloud type setting in the key-value storage
/// using the [KeyValueStorage] service. The cloud type is identified
/// by the [CloudType] enum.
///
/// [ty] - The type of cloud to be set. It must be one of the values from
/// [CloudType] enum. The corresponding integer value of the enum is stored:
/// - `CloudType.local` is stored as "0".
/// - `CloudType.supabase` is stored as "1".
/// - `CloudType.appflowyCloud` is stored as "2".
Future<void> setCloudType(CloudType ty) async {
  switch (ty) {
    case CloudType.local:
      getIt<KeyValueStorage>().set(KVKeys.kCloudType, 0.toString());
      break;
    case CloudType.supabase:
      getIt<KeyValueStorage>().set(KVKeys.kCloudType, 1.toString());
      break;
    case CloudType.appflowyCloud:
      getIt<KeyValueStorage>().set(KVKeys.kCloudType, 2.toString());
      break;
  }
}

/// Retrieves the currently set cloud type.
///
/// This method fetches the cloud type setting from the key-value storage
/// using the [KeyValueStorage] service and returns the corresponding
/// [CloudType] enum value.
///
/// Returns:
/// A Future that resolves to a [CloudType] enum value representing the
/// currently set cloud type. The default return value is `CloudType.local`
/// if no valid setting is found.
///
Future<CloudType> getCloudType() async {
  final value = await getIt<KeyValueStorage>().get(KVKeys.kCloudType);
  return value.fold(() => CloudType.local, (s) {
    switch (s) {
      case "0":
        return CloudType.local;
      case "1":
        return CloudType.supabase;
      case "2":
        return CloudType.appflowyCloud;
      default:
        return CloudType.local;
    }
  });
}

/// Determines whether authentication is enabled.
///
/// This getter evaluates if authentication should be enabled based on the
/// current integration mode and cloud type settings.
///
/// Returns:
/// A boolean value indicating whether authentication is enabled. It returns
/// `true` if the application is in release or develop mode, and the cloud type
/// is not set to `CloudType.local`. Additionally, it checks if either the
/// AppFlowy Cloud or Supabase configuration is valid.
/// Returns `false` otherwise.
bool get isAuthEnabled {
  // Only enable supabase in release and develop mode.
  if (integrationMode().isRelease || integrationMode().isDevelop) {
    final env = getIt<AppFlowyCloudSharedEnv>();
    if (env.cloudType == CloudType.local) {
      return false;
    }

    if (env.cloudType == CloudType.supabase) {
      return env.supabaseConfig.isValid;
    }

    if (env.cloudType == CloudType.appflowyCloud) {
      return env.appflowyCloudConfig.isValid;
    }

    return false;
  } else {
    return false;
  }
}

/// Checks if Supabase is enabled.
///
/// This getter evaluates if Supabase should be enabled based on the
/// current integration mode and cloud type setting.
///
/// Returns:
/// A boolean value indicating whether Supabase is enabled. It returns `true`
/// if the application is in release or develop mode and the current cloud type
/// is `CloudType.supabase`. Otherwise, it returns `false`.
bool get isSupabaseEnabled {
  // Only enable supabase in release and develop mode.
  if (integrationMode().isRelease || integrationMode().isDevelop) {
    return currentCloudType() == CloudType.supabase;
  } else {
    return false;
  }
}

/// Determines if AppFlowy Cloud is enabled.
///
/// This getter assesses if AppFlowy Cloud should be enabled based on the
/// current integration mode and cloud type setting.
///
/// Returns:
/// A boolean value indicating whether AppFlowy Cloud is enabled. It returns
/// `true` if the application is in release or develop mode and the current
/// cloud type is `CloudType.appflowyCloud`. Otherwise, it returns `false`.
bool get isAppFlowyCloudEnabled {
  // Only enable appflowy cloud in release and develop mode.
  if (integrationMode().isRelease || integrationMode().isDevelop) {
    return currentCloudType() == CloudType.appflowyCloud;
  } else {
    return false;
  }
}

enum CloudType {
  local,
  supabase,
  appflowyCloud;

  bool get isEnabled => this != CloudType.local;
  int get value {
    switch (this) {
      case CloudType.local:
        return 0;
      case CloudType.supabase:
        return 1;
      case CloudType.appflowyCloud:
        return 2;
    }
  }

  static fromValue(int value) {
    switch (value) {
      case 0:
        return CloudType.local;
      case 1:
        return CloudType.supabase;
      case 2:
        return CloudType.appflowyCloud;
      default:
        return CloudType.local;
    }
  }
}

CloudType currentCloudType() {
  return getIt<AppFlowyCloudSharedEnv>().cloudType;
}

Future<void> setAppFlowyCloudUrl(Option<String> url) async {
  await url.fold(
    () => getIt<KeyValueStorage>().remove(KVKeys.kAppflowyCloudBaseURL),
    (s) => getIt<KeyValueStorage>().set(KVKeys.kAppflowyCloudBaseURL, s),
  );
}

/// Use getIt<AppFlowyCloudSharedEnv>() to get the shared environment.
class AppFlowyCloudSharedEnv {
  final CloudType cloudType;
  final AppFlowyCloudConfiguration appflowyCloudConfig;
  final SupabaseConfiguration supabaseConfig;

  AppFlowyCloudSharedEnv({
    required this.cloudType,
    required this.appflowyCloudConfig,
    required this.supabaseConfig,
  });
}

Future<AppFlowyCloudConfiguration> getAppFlowyCloudConfig() async {
  return AppFlowyCloudConfiguration(
    base_url: await getAppFlowyCloudUrl(),
    ws_base_url: await _getAppFlowyCloudWSUrl(),
    gotrue_url: await _getAppFlowyCloudGotrueUrl(),
  );
}

Future<String> getAppFlowyCloudUrl() async {
  final result =
      await getIt<KeyValueStorage>().get(KVKeys.kAppflowyCloudBaseURL);
  return result.fold(
    () => "",
    (url) => url,
  );
}

Future<String> _getAppFlowyCloudWSUrl() async {
  try {
    final serverUrl = await getAppFlowyCloudUrl();
    final uri = Uri.parse(serverUrl);

    // Construct the WebSocket URL directly from the parsed URI.
    final wsScheme = uri.isScheme('HTTPS') ? 'wss' : 'ws';
    final wsUrl = Uri(scheme: wsScheme, host: uri.host, path: '/ws');

    return wsUrl.toString();
  } catch (e) {
    Log.error("Failed to get WebSocket URL: $e");
    return "";
  }
}

Future<String> _getAppFlowyCloudGotrueUrl() async {
  final serverUrl = await getAppFlowyCloudUrl();
  return "$serverUrl/gotrue";
}

Future<void> setSupbaseServer(
  Option<String> url,
  Option<String> anonKey,
) async {
  assert(
    (url.isSome() && anonKey.isSome()) || (url.isNone() && anonKey.isNone()),
    "Either both Supabase URL and anon key must be set, or both should be unset",
  );

  await url.fold(
    () => getIt<KeyValueStorage>().remove(KVKeys.kSupabaseURL),
    (s) => getIt<KeyValueStorage>().set(KVKeys.kSupabaseURL, s),
  );
  await anonKey.fold(
    () => getIt<KeyValueStorage>().remove(KVKeys.kSupabaseAnonKey),
    (s) => getIt<KeyValueStorage>().set(KVKeys.kSupabaseAnonKey, s),
  );
}

Future<SupabaseConfiguration> getSupabaseCloudConfig() async {
  final url = await _getSupbaseUrl();
  final anonKey = await _getSupabaseAnonKey();
  return SupabaseConfiguration(
    url: url,
    anon_key: anonKey,
  );
}

Future<String> _getSupbaseUrl() async {
  final result = await getIt<KeyValueStorage>().get(KVKeys.kSupabaseURL);
  return result.fold(
    () => "",
    (url) => url,
  );
}

Future<String> _getSupabaseAnonKey() async {
  final result = await getIt<KeyValueStorage>().get(KVKeys.kSupabaseAnonKey);
  return result.fold(
    () => "",
    (url) => url,
  );
}
