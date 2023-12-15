import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/env/env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:dartz/dartz.dart';

/// Sets the cloud type for the application.
///
/// This method updates the cloud type setting in the key-value storage
/// using the [KeyValueStorage] service. The cloud type is identified
/// by the [AuthenticatorType] enum.
///
/// [ty] - The type of cloud to be set. It must be one of the values from
/// [AuthenticatorType] enum. The corresponding integer value of the enum is stored:
/// - `CloudType.local` is stored as "0".
/// - `CloudType.supabase` is stored as "1".
/// - `CloudType.appflowyCloud` is stored as "2".
Future<void> setAuthenticatorType(AuthenticatorType ty) async {
  switch (ty) {
    case AuthenticatorType.local:
      getIt<KeyValueStorage>().set(KVKeys.kCloudType, 0.toString());
      break;
    case AuthenticatorType.supabase:
      getIt<KeyValueStorage>().set(KVKeys.kCloudType, 1.toString());
      break;
    case AuthenticatorType.appflowyCloud:
      getIt<KeyValueStorage>().set(KVKeys.kCloudType, 2.toString());
      break;
  }
}

/// Retrieves the currently set cloud type.
///
/// This method fetches the cloud type setting from the key-value storage
/// using the [KeyValueStorage] service and returns the corresponding
/// [AuthenticatorType] enum value.
///
/// Returns:
/// A Future that resolves to a [AuthenticatorType] enum value representing the
/// currently set cloud type. The default return value is `CloudType.local`
/// if no valid setting is found.
///
Future<AuthenticatorType> getAuthenticatorType() async {
  final value = await getIt<KeyValueStorage>().get(KVKeys.kCloudType);
  return value.fold(() => AuthenticatorType.local, (s) {
    switch (s) {
      case "0":
        return AuthenticatorType.local;
      case "1":
        return AuthenticatorType.supabase;
      case "2":
        return AuthenticatorType.appflowyCloud;
      default:
        return AuthenticatorType.local;
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
  if (integrationMode().isRelease ||
      integrationMode().isDevelop ||
      integrationMode().isIntegrationTest) {
    final env = getIt<AppFlowyCloudSharedEnv>();
    if (env.authenticatorType == AuthenticatorType.supabase) {
      return env.supabaseConfig.isValid;
    }

    if (env.authenticatorType == AuthenticatorType.appflowyCloud) {
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
  if (integrationMode().isRelease ||
      integrationMode().isDevelop ||
      integrationMode().isIntegrationTest) {
    return currentCloudType() == AuthenticatorType.supabase;
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
  if (integrationMode().isRelease ||
      integrationMode().isDevelop ||
      integrationMode().isIntegrationTest) {
    return currentCloudType() == AuthenticatorType.appflowyCloud;
  } else {
    return false;
  }
}

enum AuthenticatorType {
  local,
  supabase,
  appflowyCloud;

  bool get isEnabled => this != AuthenticatorType.local;
  int get value {
    switch (this) {
      case AuthenticatorType.local:
        return 0;
      case AuthenticatorType.supabase:
        return 1;
      case AuthenticatorType.appflowyCloud:
        return 2;
    }
  }

  static AuthenticatorType fromValue(int value) {
    switch (value) {
      case 0:
        return AuthenticatorType.local;
      case 1:
        return AuthenticatorType.supabase;
      case 2:
        return AuthenticatorType.appflowyCloud;
      default:
        return AuthenticatorType.local;
    }
  }
}

AuthenticatorType currentCloudType() {
  return getIt<AppFlowyCloudSharedEnv>().authenticatorType;
}

Future<void> setAppFlowyCloudUrl(Option<String> url) async {
  await url.fold(
    () => getIt<KeyValueStorage>().remove(KVKeys.kAppflowyCloudBaseURL),
    (s) => getIt<KeyValueStorage>().set(KVKeys.kAppflowyCloudBaseURL, s),
  );
}

/// Use getIt<AppFlowyCloudSharedEnv>() to get the shared environment.
class AppFlowyCloudSharedEnv {
  final AuthenticatorType _authenticatorType;
  final AppFlowyCloudConfiguration appflowyCloudConfig;
  final SupabaseConfiguration supabaseConfig;

  AppFlowyCloudSharedEnv({
    required AuthenticatorType authenticatorType,
    required this.appflowyCloudConfig,
    required this.supabaseConfig,
  }) : _authenticatorType = authenticatorType;

  AuthenticatorType get authenticatorType => _authenticatorType;

  static Future<AppFlowyCloudSharedEnv> fromEnv() async {
    // If [Env.enableCustomCloud] is true, then use the custom cloud configuration.
    if (Env.enableCustomCloud) {
      // Use the custom cloud configuration.
      final cloudType = await getAuthenticatorType();
      final appflowyCloudConfig = await getAppFlowyCloudConfig();
      final supabaseCloudConfig = await getSupabaseCloudConfig();

      return AppFlowyCloudSharedEnv(
        authenticatorType: cloudType,
        appflowyCloudConfig: appflowyCloudConfig,
        supabaseConfig: supabaseCloudConfig,
      );
    } else {
      // Using the cloud settings from the .env file.
      final appflowyCloudConfig = AppFlowyCloudConfiguration(
        base_url: Env.afCloudUrl,
        ws_base_url: await _getAppFlowyCloudWSUrl(Env.afCloudUrl),
        gotrue_url: await _getAppFlowyCloudGotrueUrl(Env.afCloudUrl),
      );

      return AppFlowyCloudSharedEnv(
        authenticatorType: AuthenticatorType.fromValue(Env.authenticatorType),
        appflowyCloudConfig: appflowyCloudConfig,
        supabaseConfig: SupabaseConfiguration.defaultConfig(),
      );
    }
  }
}

Future<AppFlowyCloudConfiguration> configurationFromUri(
  Uri baseUri,
  String baseUrl,
) async {
// When the host is set to 'localhost', the application will utilize the local configuration. This setup assumes that 'localhost' does not employ a reverse proxy, therefore default port settings are used.
  if (baseUri.host == "localhost") {
    return AppFlowyCloudConfiguration(
      base_url: "$baseUrl:8000",
      ws_base_url: "ws://${baseUri.host}:8000/ws",
      gotrue_url: "$baseUrl:9998",
    );
  } else {
    return AppFlowyCloudConfiguration(
      base_url: baseUrl,
      ws_base_url: await _getAppFlowyCloudWSUrl(baseUrl),
      gotrue_url: await _getAppFlowyCloudGotrueUrl(baseUrl),
    );
  }
}

Future<AppFlowyCloudConfiguration> getAppFlowyCloudConfig() async {
  final baseURL = await getAppFlowyCloudUrl();

  try {
    final uri = Uri.parse(baseURL);
    return await configurationFromUri(uri, baseURL);
  } catch (e) {
    Log.error("Failed to parse AppFlowy Cloud URL: $e");
    return AppFlowyCloudConfiguration.defaultConfig();
  }
}

Future<String> getAppFlowyCloudUrl() async {
  final result =
      await getIt<KeyValueStorage>().get(KVKeys.kAppflowyCloudBaseURL);
  return result.fold(
    () => "",
    (url) => url,
  );
}

Future<String> _getAppFlowyCloudWSUrl(String baseURL) async {
  try {
    final uri = Uri.parse(baseURL);

    // Construct the WebSocket URL directly from the parsed URI.
    final wsScheme = uri.isScheme('HTTPS') ? 'wss' : 'ws';
    final wsUrl = Uri(scheme: wsScheme, host: uri.host, path: '/ws');

    return wsUrl.toString();
  } catch (e) {
    Log.error("Failed to get WebSocket URL: $e");
    return "";
  }
}

Future<String> _getAppFlowyCloudGotrueUrl(String baseURL) async {
  return "$baseURL/gotrue";
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
