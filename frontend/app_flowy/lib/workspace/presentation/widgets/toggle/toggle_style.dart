import 'package:flowy_infra/theme.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

class ToggleStyle {
  final double height;
  final double width;

  final double thumbRadius;

  final Color backgroundColor;
  final Color thumbColor;

  ToggleStyle({
    required this.height,
    required this.width,
    required this.thumbRadius,
    required this.backgroundColor,
    required this.thumbColor,
  });

  ToggleStyle.big(AppTheme theme)
      : height = 16,
        width = 27,
        thumbRadius = 14,
        backgroundColor = theme.main1,
        thumbColor = theme.surface;

  ToggleStyle.small(AppTheme theme)
      : height = 10,
        width = 16,
        thumbRadius = 8,
        backgroundColor = theme.main1,
        thumbColor = theme.surface;
}
