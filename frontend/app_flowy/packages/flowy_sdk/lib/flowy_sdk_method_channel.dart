import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flowy_sdk_platform_interface.dart';

/// An implementation of [FlowySdkPlatform] that uses method channels.
class MethodChannelFlowySdk extends FlowySdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flowy_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
