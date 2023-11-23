// lib/env/env.dart
import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:dartz/dartz.dart';

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
}

CloudType currentCloudType() {
  return getIt<AppFlowyCloudSharedEnv>().cloudType;
}

Future<void> setAppFlowyCloudBaseUrl(Option<String> url) async {
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
    ws_base_url: await getAppFlowyCloudWSUrl(),
    gotrue_url: await getAppFlowyCloudGotrueUrl(),
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

Future<void> setSupbaseServer(
  Option<String> url,
  Option<String> anonKey,
) async {
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
  final url = await getSupbaseUrl();
  final anonKey = await getSupabaseAnonKey();
  return SupabaseConfiguration(
    url: url,
    anon_key: anonKey,
  );
}

Future<String> getSupbaseUrl() async {
  final result = await getIt<KeyValueStorage>().get(KVKeys.kSupabaseURL);
  return result.fold(
    () => "",
    (url) => url,
  );
}

Future<String> getSupabaseAnonKey() async {
  final result = await getIt<KeyValueStorage>().get(KVKeys.kSupabaseAnonKey);
  return result.fold(
    () => "",
    (url) => url,
  );
}
