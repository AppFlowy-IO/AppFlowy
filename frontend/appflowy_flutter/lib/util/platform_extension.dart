import 'dart:io';
import 'package:flutter/foundation.dart';

bool evalByPlatform({
  required bool mobile,
  required bool desktop,
}) =>
   PlatformExtension.isMobile ? mobile : desktop;

extension PlatformExtension on Platform {
  static bool get isMobile {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }
}
