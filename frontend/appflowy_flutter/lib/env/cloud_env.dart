import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/env/backend_env.dart';
import 'package:appflowy/env/env.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';

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
Future<void> _setAuthenticatorType(AuthenticatorType ty) async {
  switch (ty) {
    case AuthenticatorType.local:
      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, 0.toString());
      break;
    case AuthenticatorType.supabase:
      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, 1.toString());
      break;
    case AuthenticatorType.appflowyCloud:
      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, 2.toString());
      break;
    case AuthenticatorType.appflowyCloudSelfHost:
      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, 3.toString());
      break;
    case AuthenticatorType.appflowyCloudDevelop:
      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, 4.toString());
      break;
  }
}

const String kAppflowyCloudUrl = "https://beta.appflowy.cloud";

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
  if (value == null && !integrationMode().isUnitTest) {
    // if the cloud type is not set, then set it to AppFlowy Cloud as default.
    await useAppFlowyBetaCloudWithURL(
      kAppflowyCloudUrl,
      AuthenticatorType.appflowyCloud,
    );
    return AuthenticatorType.appflowyCloud;
  }

  switch (value ?? "0") {
    case "0":
      return AuthenticatorType.local;
    case "1":
      return AuthenticatorType.supabase;
    case "2":
      return AuthenticatorType.appflowyCloud;
    case "3":
      return AuthenticatorType.appflowyCloudSelfHost;
    case "4":
      return AuthenticatorType.appflowyCloudDevelop;
    default:
      await useAppFlowyBetaCloudWithURL(
        kAppflowyCloudUrl,
        AuthenticatorType.appflowyCloud,
      );
      return AuthenticatorType.appflowyCloud;
  }
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
  final env = getIt<AppFlowyCloudSharedEnv>();
  if (env.authenticatorType == AuthenticatorType.supabase) {
    return env.supabaseConfig.isValid;
  }

  if (env.authenticatorType.isAppFlowyCloudEnabled) {
    return env.appflowyCloudConfig.isValid;
  }

  return false;
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
  return currentCloudType().isSupabaseEnabled;
}

/// Determines if AppFlowy Cloud is enabled.
bool get isAppFlowyCloudEnabled {
  return currentCloudType().isAppFlowyCloudEnabled;
}

enum AuthenticatorType {
  local,
  supabase,
  appflowyCloud,
  appflowyCloudSelfHost,
  // The 'appflowyCloudDevelop' type is used for develop purposes only.
  appflowyCloudDevelop;

  bool get isLocal => this == AuthenticatorType.local;

  bool get isAppFlowyCloudEnabled =>
      this == AuthenticatorType.appflowyCloudSelfHost ||
      this == AuthenticatorType.appflowyCloudDevelop ||
      this == AuthenticatorType.appflowyCloud;

  bool get isSupabaseEnabled => this == AuthenticatorType.supabase;

  int get value {
    switch (this) {
      case AuthenticatorType.local:
        return 0;
      case AuthenticatorType.supabase:
        return 1;
      case AuthenticatorType.appflowyCloud:
        return 2;
      case AuthenticatorType.appflowyCloudSelfHost:
        return 3;
      case AuthenticatorType.appflowyCloudDevelop:
        return 4;
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
      case 3:
        return AuthenticatorType.appflowyCloudSelfHost;
      case 4:
        return AuthenticatorType.appflowyCloudDevelop;
      default:
        return AuthenticatorType.local;
    }
  }
}

AuthenticatorType currentCloudType() {
  return getIt<AppFlowyCloudSharedEnv>().authenticatorType;
}

Future<void> _setAppFlowyCloudUrl(String? url) async {
  await getIt<KeyValueStorage>().set(KVKeys.kAppflowyCloudBaseURL, url ?? '');
}

Future<void> useSelfHostedAppFlowyCloudWithURL(String url) async {
  await _setAuthenticatorType(AuthenticatorType.appflowyCloudSelfHost);
  await _setAppFlowyCloudUrl(url);
}

Future<void> useAppFlowyBetaCloudWithURL(
  String url,
  AuthenticatorType authenticatorType,
) async {
  await _setAuthenticatorType(authenticatorType);
  await _setAppFlowyCloudUrl(url);
}

Future<void> useLocalServer() async {
  await _setAuthenticatorType(AuthenticatorType.local);
}

Future<void> useSupabaseCloud({
  required String url,
  required String anonKey,
}) async {
  await _setAuthenticatorType(AuthenticatorType.supabase);
  await setSupabaseServer(url, anonKey);
}

/// Use getIt<AppFlowyCloudSharedEnv>() to get the shared environment.
class AppFlowyCloudSharedEnv {
  AppFlowyCloudSharedEnv({
    required AuthenticatorType authenticatorType,
    required this.appflowyCloudConfig,
    required this.supabaseConfig,
  }) : _authenticatorType = authenticatorType;

  final AuthenticatorType _authenticatorType;
  final AppFlowyCloudConfiguration appflowyCloudConfig;
  final SupabaseConfiguration supabaseConfig;

  AuthenticatorType get authenticatorType => _authenticatorType;

  static Future<AppFlowyCloudSharedEnv> fromEnv() async {
    // If [Env.enableCustomCloud] is true, then use the custom cloud configuration.
    if (Env.enableCustomCloud) {
      // Use the custom cloud configuration.
      var authenticatorType = await getAuthenticatorType();

      final appflowyCloudConfig = authenticatorType.isAppFlowyCloudEnabled
          ? await getAppFlowyCloudConfig(authenticatorType)
          : AppFlowyCloudConfiguration.defaultConfig();

      final supabaseCloudConfig = authenticatorType.isSupabaseEnabled
          ? await getSupabaseCloudConfig()
          : SupabaseConfiguration.defaultConfig();

      // In the backend, the value '2' represents the use of AppFlowy Cloud. However, in the frontend,
      // we distinguish between [AuthenticatorType.appflowyCloudSelfHost] and [AuthenticatorType.appflowyCloud].
      // When the cloud type is [AuthenticatorType.appflowyCloudSelfHost] in the frontend, it should be
      // converted to [AuthenticatorType.appflowyCloud] to align with the backend representation,
      // where both types are indicated by the value '2'.
      if (authenticatorType.isAppFlowyCloudEnabled) {
        authenticatorType = AuthenticatorType.appflowyCloud;
      }
      return AppFlowyCloudSharedEnv(
        authenticatorType: authenticatorType,
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

  @override
  String toString() {
    return 'authenticator: $_authenticatorType\n'
        'appflowy: ${appflowyCloudConfig.toJson()}\n'
        'supabase: ${supabaseConfig.toJson()})\n';
  }
}

Future<AppFlowyCloudConfiguration> configurationFromUri(
  Uri baseUri,
  String baseUrl,
  AuthenticatorType authenticatorType,
) async {
  // In development mode, the app is configured to access the AppFlowy cloud server directly through specific ports.
  // This setup bypasses the need for Nginx, meaning that the AppFlowy cloud should be running without an Nginx server
  // in the development environment.
  if (authenticatorType == AuthenticatorType.appflowyCloudDevelop) {
    return AppFlowyCloudConfiguration(
      base_url: "$baseUrl:8000",
      ws_base_url: "ws://${baseUri.host}:8000/ws/v1",
      gotrue_url: "$baseUrl:9999",
    );
  } else {
    return AppFlowyCloudConfiguration(
      base_url: baseUrl,
      ws_base_url: await _getAppFlowyCloudWSUrl(baseUrl),
      gotrue_url: await _getAppFlowyCloudGotrueUrl(baseUrl),
    );
  }
}

Future<AppFlowyCloudConfiguration> getAppFlowyCloudConfig(
  AuthenticatorType authenticatorType,
) async {
  final baseURL = await getAppFlowyCloudUrl();

  try {
    final uri = Uri.parse(baseURL);
    return await configurationFromUri(uri, baseURL, authenticatorType);
  } catch (e) {
    Log.error("Failed to parse AppFlowy Cloud URL: $e");
    return AppFlowyCloudConfiguration.defaultConfig();
  }
}

Future<String> getAppFlowyCloudUrl() async {
  final result =
      await getIt<KeyValueStorage>().get(KVKeys.kAppflowyCloudBaseURL);
  return result ?? kAppflowyCloudUrl;
}

Future<String> _getAppFlowyCloudWSUrl(String baseURL) async {
  try {
    final uri = Uri.parse(baseURL);

    // Construct the WebSocket URL directly from the parsed URI.
    final wsScheme = uri.isScheme('HTTPS') ? 'wss' : 'ws';
    final wsUrl =
        Uri(scheme: wsScheme, host: uri.host, port: uri.port, path: '/ws/v1');

    return wsUrl.toString();
  } catch (e) {
    Log.error("Failed to get WebSocket URL: $e");
    return "";
  }
}

Future<String> _getAppFlowyCloudGotrueUrl(String baseURL) async {
  return "$baseURL/gotrue";
}

Future<void> setSupabaseServer(
  String? url,
  String? anonKey,
) async {
  assert(
    (url != null && anonKey != null) || (url == null && anonKey == null),
    "Either both Supabase URL and anon key must be set, or both should be unset",
  );

  if (url == null) {
    await getIt<KeyValueStorage>().remove(KVKeys.kSupabaseURL);
  } else {
    await getIt<KeyValueStorage>().set(KVKeys.kSupabaseURL, url);
  }

  if (anonKey == null) {
    await getIt<KeyValueStorage>().remove(KVKeys.kSupabaseAnonKey);
  } else {
    await getIt<KeyValueStorage>().set(KVKeys.kSupabaseAnonKey, anonKey);
  }
}

Future<SupabaseConfiguration> getSupabaseCloudConfig() async {
  final url = await _getSupabaseUrl();
  final anonKey = await _getSupabaseAnonKey();
  return SupabaseConfiguration(
    url: url,
    anon_key: anonKey,
  );
}

Future<String> _getSupabaseUrl() async {
  final result = await getIt<KeyValueStorage>().get(KVKeys.kSupabaseURL);
  return result ?? '';
}

Future<String> _getSupabaseAnonKey() async {
  final result = await getIt<KeyValueStorage>().get(KVKeys.kSupabaseAnonKey);
  return result ?? '';
}
