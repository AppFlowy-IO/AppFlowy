import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class PrimaryRoundedButton extends StatelessWidget {
  const PrimaryRoundedButton({
    super.key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.radius,
    this.margin,
    this.onTap,
    this.hoverColor,
    this.backgroundColor,
    this.useIntrinsicWidth = true,
    this.lineHeight,
    this.figmaLineHeight,
  });

  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final double? radius;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? hoverColor;
  final Color? backgroundColor;
  final bool useIntrinsicWidth;
  final double? lineHeight;
  final double? figmaLineHeight;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      useIntrinsicWidth: useIntrinsicWidth,
      text: FlowyText(
        text,
        fontSize: fontSize ?? 14.0,
        fontWeight: fontWeight ?? FontWeight.w500,
        lineHeight: lineHeight ?? 1.0,
        figmaLineHeight: figmaLineHeight,
        color: Theme.of(context).colorScheme.onPrimary,
        textAlign: TextAlign.center,
      ),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 14.0),
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      hoverColor:
          hoverColor ?? Theme.of(context).colorScheme.primary.withOpacity(0.9),
      radius: BorderRadius.circular(radius ?? 10.0),
      onTap: onTap,
    );
  }
}

class OutlinedRoundedButton extends StatelessWidget {
  const OutlinedRoundedButton({
    super.key,
    required this.text,
    this.onTap,
    this.margin,
    this.radius,
  });

  final String text;
  final VoidCallback? onTap;
  final EdgeInsets? margin;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: Theme.of(context).brightness == Brightness.light
              ? const BorderSide(color: Color(0x1E14171B))
              : const BorderSide(color: Colors.white10),
          borderRadius: BorderRadius.circular(radius ?? 8),
        ),
      ),
      child: FlowyButton(
        useIntrinsicWidth: true,
        margin: margin ??
            const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 9.0,
            ),
        radius: BorderRadius.circular(radius ?? 8),
        text: FlowyText.regular(
          text,
          lineHeight: 1.0,
          textAlign: TextAlign.center,
        ),
        onTap: onTap,
      ),
    );
  }
}
