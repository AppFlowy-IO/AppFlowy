import 'package:flutter/material.dart';

class AFFilledButton extends StatelessWidget {
  const AFFilledButton({
    super.key,
    required this.onTap,
    required this.child,
    required this.padding,
    required this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledColor,
    this.textColor,
    this.textDisabledColor,
    this.hoverColor,
    this.disabled = false,
  });

  final VoidCallback? onTap;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledColor;
  final Color? textColor;
  final Color? textDisabledColor;
  final Color? hoverColor;

  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool disabled;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: disabled ? disabledColor : backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: InkWell(
        onTap: disabled ? null : onTap,
        hoverColor: disabled ? null : hoverColor,
        child: Padding(
          padding: padding,
          child: Center(
            child: child,
          ),
        ),
      ),
    );
  }
}
