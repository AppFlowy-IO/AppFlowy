import 'package:flowy_infra/theme.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

class ToggleStyle {
  final double height;
  final double width;

  final double thumbRadius;
  final Color thumbColor;
  final Color activeBackgroundColor;
  final Color inactiveBackgroundColor;

  ToggleStyle({
    required this.height,
    required this.width,
    required this.thumbRadius,
    required this.thumbColor,
    required this.activeBackgroundColor,
    required this.inactiveBackgroundColor,
  });

  ToggleStyle.big(AppTheme theme)
      : height = 16,
        width = 27,
        thumbRadius = 14,
        activeBackgroundColor = theme.main1,
        inactiveBackgroundColor = theme.shader5,
        thumbColor = theme.surface;

  ToggleStyle.small(AppTheme theme)
      : height = 10,
        width = 16,
        thumbRadius = 8,
        activeBackgroundColor = theme.main1,
        inactiveBackgroundColor = theme.shader5,
        thumbColor = theme.surface;
}
