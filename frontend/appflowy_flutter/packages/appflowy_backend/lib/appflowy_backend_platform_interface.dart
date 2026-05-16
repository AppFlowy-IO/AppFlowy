import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appflowy_backend_method_channel.dart';

abstract class AppFlowyBackendPlatform extends PlatformInterface {
  /// Constructs a FlowySdkPlatform.
  AppFlowyBackendPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppFlowyBackendPlatform _instance = MethodChannelFlowySdk();

  /// The default instance of [AppFlowyBackendPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlowySdk].
  static AppFlowyBackendPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AppFlowyBackendPlatform] when
  /// they register themselves.
  static set instance(AppFlowyBackendPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
