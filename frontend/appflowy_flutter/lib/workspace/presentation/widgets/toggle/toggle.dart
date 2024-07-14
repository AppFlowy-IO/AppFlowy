import 'package:flutter/material.dart';

import 'package:flowy_infra/theme_extension.dart';

class ToggleStyle {
  const ToggleStyle({
    required this.height,
    required this.width,
    required this.thumbRadius,
  });

  const ToggleStyle.big()
      : height = 16,
        width = 27,
        thumbRadius = 14;

  const ToggleStyle.small()
      : height = 10,
        width = 16,
        thumbRadius = 8;

  const ToggleStyle.mobile()
      : height = 24,
        width = 42,
        thumbRadius = 18;

  final double height;
  final double width;
  final double thumbRadius;
}

class Toggle extends StatelessWidget {
  const Toggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.style = const ToggleStyle.big(),
    this.thumbColor,
    this.activeBackgroundColor,
    this.inactiveBackgroundColor,
    this.padding = const EdgeInsets.all(8.0),
  });

  final bool value;
  final void Function(bool) onChanged;
  final ToggleStyle style;
  final Color? thumbColor;
  final Color? activeBackgroundColor;
  final Color? inactiveBackgroundColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = value
        ? activeBackgroundColor ?? Theme.of(context).colorScheme.primary
        : inactiveBackgroundColor ??
            AFThemeExtension.of(context).toggleButtonBGColor;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Padding(
        padding: padding,
        child: Stack(
          children: [
            Container(
              height: style.height,
              width: style.width,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(style.height / 2),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              top: (style.height - style.thumbRadius) / 2,
              left: value ? style.width - style.thumbRadius - 1 : 1,
              child: Container(
                height: style.thumbRadius,
                width: style.thumbRadius,
                decoration: BoxDecoration(
                  color: thumbColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(style.thumbRadius / 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
