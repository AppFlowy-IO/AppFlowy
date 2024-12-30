import 'package:appflowy/util/theme_extension.dart';
import 'package:flutter/material.dart';

extension PickerColors on BuildContext {
  Color get pickerTextColor {
    return Theme.of(this).isLightMode
        ? const Color(0x80171717)
        : Colors.white.withOpacity(0.5);
  }

  Color get pickerIconColor {
    return Theme.of(this).isLightMode ? const Color(0xFF171717) : Colors.white;
  }

  Color get pickerSearchBarBorderColor {
    return Theme.of(this).isLightMode
        ? const Color(0x1E171717)
        : Colors.white.withOpacity(0.12);
  }

  Color get pickerButtonBoarderColor {
    return Theme.of(this).isLightMode
        ? const Color(0x1E171717)
        : Colors.white.withOpacity(0.12);
  }
}
