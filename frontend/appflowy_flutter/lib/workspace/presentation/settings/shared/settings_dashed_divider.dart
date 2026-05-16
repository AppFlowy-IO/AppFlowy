import 'package:flutter/material.dart';

/// Renders a dashed divider
///
/// The length of each dash is the same as the gap.
///
class SettingsDashedDivider extends StatelessWidget {
  const SettingsDashedDivider({
    super.key,
    this.color,
    this.height,
    this.strokeWidth = 1.0,
    this.gap = 3.0,
    this.direction = Axis.horizontal,
  });

  // The color of the divider, defaults to the theme's divider color
  final Color? color;

  // The height of the divider, this will surround the divider equally
  final double? height;

  // Thickness of the divider
  final double strokeWidth;

  // Gap between the dashes
  final double gap;

  // Direction of the divider
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    final double padding =
        height != null && height! > 0 ? (height! - strokeWidth) / 2 : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final items = _calculateItems(constraints);
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: direction == Axis.horizontal ? padding : 0,
            horizontal: direction == Axis.vertical ? padding : 0,
          ),
          child: Wrap(
            direction: direction,
            children: List.generate(
              items,
              (index) => Container(
                margin: EdgeInsets.only(
                  right: direction == Axis.horizontal ? gap : 0,
                  bottom: direction == Axis.vertical ? gap : 0,
                ),
                width: direction == Axis.horizontal ? gap : strokeWidth,
                height: direction == Axis.vertical ? gap : strokeWidth,
                decoration: BoxDecoration(
                  color: color ?? Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _calculateItems(BoxConstraints constraints) {
    final double totalLength = direction == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;

    return (totalLength / (gap * 2)).floor();
  }
}
