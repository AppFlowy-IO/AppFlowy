import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';

class RoundedTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? title;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color borderColor;
  final Color? fillColor;
  final Color? hoverColor;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsets padding;

  const RoundedTextButton({
    super.key,
    this.onPressed,
    this.title,
    this.width,
    this.height,
    this.borderRadius,
    this.borderColor = Colors.transparent,
    this.fillColor,
    this.hoverColor,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 10,
        maxWidth: width ?? double.infinity,
        minHeight: 10,
        maxHeight: height ?? 60,
      ),
      child: SizedBox.expand(
        child: FlowyTextButton(
          title ?? '',
          fontWeight: fontWeight,
          onPressed: onPressed,
          fontSize: fontSize,
          mainAxisAlignment: MainAxisAlignment.center,
          radius: borderRadius ?? Corners.s6Border,
          fontColor: textColor ?? Theme.of(context).colorScheme.onPrimary,
          fillColor: fillColor ?? Theme.of(context).colorScheme.primary,
          textColor: textColor,
          hoverColor:
              hoverColor ?? Theme.of(context).colorScheme.primaryContainer,
          padding: padding,
          
        ),
      ),
    );
  }
}

class RoundedImageButton extends StatelessWidget {
  final VoidCallback? press;
  final double size;
  final BorderRadius borderRadius;
  final Color borderColor;
  final Color color;
  final Widget child;

  const RoundedImageButton({
    super.key,
    this.press,
    required this.size,
    this.borderRadius = BorderRadius.zero,
    this.borderColor = Colors.transparent,
    this.color = Colors.transparent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TextButton(
        onPressed: press,
        style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(borderRadius: borderRadius))),
        child: child,
      ),
    );
  }
}
