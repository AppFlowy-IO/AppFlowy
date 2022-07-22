import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flowy_board_method_channel.dart';

abstract class FlowyBoardPlatform extends PlatformInterface {
  /// Constructs a FlowyBoardPlatform.
  FlowyBoardPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlowyBoardPlatform _instance = MethodChannelFlowyBoard();

  /// The default instance of [FlowyBoardPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlowyBoard].
  static FlowyBoardPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlowyBoardPlatform] when
  /// they register themselves.
  static set instance(FlowyBoardPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
