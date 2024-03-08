import 'package:flowy_infra/time/duration.dart';
import 'package:flutter/material.dart';

class FlowyContainer extends StatelessWidget {
  final Color color;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? shadows;
  final Widget? child;
  final double? width;
  final double? height;
  final Alignment? align;
  final EdgeInsets? margin;
  final Duration? duration;
  final BoxBorder? border;

  const FlowyContainer(this.color,
      {super.key,
      this.borderRadius,
      this.shadows,
      this.child,
      this.width,
      this.height,
      this.align,
      this.margin,
      this.duration,
      this.border});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        width: width,
        height: height,
        margin: margin,
        alignment: align,
        duration: duration ?? FlowyDurations.medium,
        decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            boxShadow: shadows,
            border: border),
        child: child);
  }
}
