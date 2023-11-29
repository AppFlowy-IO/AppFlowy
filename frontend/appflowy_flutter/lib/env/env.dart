// lib/env/env.dart
import 'package:appflowy/env/cloud_env.dart';
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  static bool get enableCustomCloud {
    return Env.authenticatorType == AuthenticatorType.appflowyCloud.value &&
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
}
