import 'package:appflowy/util/theme_extension.dart';
import 'package:flutter/material.dart';

extension NotificationItemColors on BuildContext {
  Color get notificationItemTextColor {
    if (Theme.of(this).isLightMode) {
      return const Color(0xFF171717);
    }
    return const Color(0xFFffffff).withValues(alpha: 0.8);
  }
}
