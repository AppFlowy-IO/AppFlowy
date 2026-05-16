library flowy_infra_ui_platform_interface;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'src/method_channel_flowy_infra_ui.dart';

abstract class FlowyInfraUIPlatform extends PlatformInterface {
  FlowyInfraUIPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlowyInfraUIPlatform _instance = MethodChannelFlowyInfraUI();

  static FlowyInfraUIPlatform get instance => _instance;

  static set instance(FlowyInfraUIPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<bool> get onKeyboardVisibilityChange {
    throw UnimplementedError(
        '`onKeyboardChange` should be overridden by subclass.');
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError(
        '`getPlatformVersion` should be overridden by subclass.');
  }
}
