import 'package:appflowy/util/theme_extension.dart';
import 'package:flutter/material.dart';

class ShareMenuColors {
  static Color borderColor(BuildContext context) {
    final borderColor = Theme.of(context).isLightMode
        ? const Color(0x1E14171B)
        : Colors.white.withOpacity(0.1);
    return borderColor;
  }
}
