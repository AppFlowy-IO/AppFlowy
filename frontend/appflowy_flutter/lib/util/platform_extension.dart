import 'dart:io';
import 'package:flutter/foundation.dart';

extension PlatformExtension on Platform {
  static bool get isMobile {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }
}
