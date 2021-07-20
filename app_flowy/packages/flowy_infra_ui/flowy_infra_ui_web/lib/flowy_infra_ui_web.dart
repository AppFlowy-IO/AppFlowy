library flowy_infra_ui_web;

import 'dart:html' as html show window;
import 'package:flowy_infra_ui_platform_interface/flowy_infra_ui_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class FlowyInfraUIPlugin extends FlowyInfraUIPlatform {
  static void registerWith(Registrar registrar) {
    FlowyInfraUIPlatform.instance = FlowyInfraUIPlugin();
  }

  // MARK: - Keyboard

  @override
  Stream<bool> get onKeyboardVisibilityChange async* {
    // suppose that keyboard won't show in web side
    yield false;
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = html.window.navigator.userAgent;
    return Future.value(version);
  }
}
