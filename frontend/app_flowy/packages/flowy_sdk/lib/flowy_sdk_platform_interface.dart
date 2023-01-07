import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flowy_sdk_method_channel.dart';

abstract class FlowySdkPlatform extends PlatformInterface {
  /// Constructs a FlowySdkPlatform.
  FlowySdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlowySdkPlatform _instance = MethodChannelFlowySdk();

  /// The default instance of [FlowySdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlowySdk].
  static FlowySdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlowySdkPlatform] when
  /// they register themselves.
  static set instance(FlowySdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
