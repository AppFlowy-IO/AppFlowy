import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flowy_board_platform_interface.dart';

/// An implementation of [FlowyBoardPlatform] that uses method channels.
class MethodChannelFlowyBoard extends FlowyBoardPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flowy_board');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
