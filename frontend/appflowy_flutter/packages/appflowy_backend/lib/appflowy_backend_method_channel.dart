import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appflowy_backend_platform_interface.dart';

/// An implementation of [AppFlowyBackendPlatform] that uses method channels.
class MethodChannelFlowySdk extends AppFlowyBackendPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appflowy_backend');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
