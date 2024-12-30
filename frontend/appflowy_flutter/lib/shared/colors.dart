import 'package:appflowy/util/theme_extension.dart';
import 'package:flutter/material.dart';

extension SharedColors on BuildContext {
  Color get proPrimaryColor {
    return Theme.of(this).isLightMode
        ? const Color(0xFF653E8C)
        : const Color(0xFFE8E2EE);
  }

  Color get proSecondaryColor {
    return Theme.of(this).isLightMode
        ? const Color(0xFFE8E2EE)
        : const Color(0xFF653E8C);
  }
}
