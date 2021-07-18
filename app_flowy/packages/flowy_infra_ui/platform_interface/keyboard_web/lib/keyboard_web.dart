library keyboard_web;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:keyboard_platform_interface/keyboard_platform_interface.dart';

class KeyboardPlugin extends KeyboardPlatform {
  static void registerWith(Registrar registrar) {
    KeyboardPlatform.instance = KeyboardPlugin();
  }

  @override
  Stream<bool> get onKeyboardChange async* {
    // suppose that keyboard won't show in web side
    yield false;
  }
}
