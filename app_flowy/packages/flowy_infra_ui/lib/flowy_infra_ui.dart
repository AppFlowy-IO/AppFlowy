
import 'dart:async';

import 'package:flutter/services.dart';

class FlowyInfraUi {
  static const MethodChannel _channel = MethodChannel('flowy_infra_ui');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
