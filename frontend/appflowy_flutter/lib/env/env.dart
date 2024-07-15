// lib/env/env.dart
import 'package:appflowy/env/cloud_env.dart';
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  // This flag is used to decide if users can dynamically configure cloud settings. It turns true when a .env file exists containing the APPFLOWY_CLOUD_URL variable. By default, this is set to false.
  static bool get enableCustomCloud {
    return Env.authenticatorType ==
            AuthenticatorType.appflowyCloudSelfHost.value ||
        Env.authenticatorType == AuthenticatorType.appflowyCloud.value ||
        Env.authenticatorType == AuthenticatorType.appflowyCloudDevelop.value &&
            _Env.afCloudUrl.isEmpty;
  }

  @EnviedField(
    obfuscate: false,
    varName: 'AUTHENTICATOR_TYPE',
    defaultValue: 2,
  )
  static const int authenticatorType = _Env.authenticatorType;

  /// AppFlowy Cloud Configuration
  @EnviedField(
    obfuscate: false,
    varName: 'APPFLOWY_CLOUD_URL',
    defaultValue: '',
  )
  static const String afCloudUrl = _Env.afCloudUrl;

  @EnviedField(
    obfuscate: false,
    varName: 'INTERNAL_BUILD',
    defaultValue: '',
  )
  static const String internalBuild = _Env.internalBuild;
}
