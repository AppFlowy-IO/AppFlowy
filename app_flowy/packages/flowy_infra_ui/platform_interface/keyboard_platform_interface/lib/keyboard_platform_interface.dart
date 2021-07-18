library keyboard_platform_interface;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'src/method_channel_keyboard.dart';

abstract class KeyboardPlatform extends PlatformInterface {
  KeyboardPlatform() : super(token: _token);

  static final Object _token = Object();

  static KeyboardPlatform _instance = MethodChannelKeyboard();

  static KeyboardPlatform get instance => _instance;

  static set instance(KeyboardPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<bool> get onKeyboardChange {
    throw UnimplementedError('`onKeyboardChange` should be overrided by subclass.');
  }
}
