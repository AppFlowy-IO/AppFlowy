import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

class Toggle extends StatelessWidget {
  final ToggleStyle style;
  final bool value;
  final Color? thumbColor;
  final Color? activeBackgroundColor;
  final Color? inactiveBackgroundColor;
  final void Function(bool) onChanged;
  final EdgeInsets padding;

  const Toggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.style,
    this.thumbColor,
    this.activeBackgroundColor,
    this.inactiveBackgroundColor,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = value
        ? activeBackgroundColor ?? Theme.of(context).colorScheme.primary
        : activeBackgroundColor ?? AFThemeExtension.of(context).toggleOffFill;
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
                  color: thumbColor ?? Theme.of(context).colorScheme.onPrimary,
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
