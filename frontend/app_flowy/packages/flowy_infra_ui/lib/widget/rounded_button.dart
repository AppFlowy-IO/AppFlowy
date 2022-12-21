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

  const RoundedTextButton({
    Key? key,
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
  }) : super(key: key);

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
          onPressed: onPressed,
          fontSize: fontSize,
          mainAxisAlignment: MainAxisAlignment.center,
          radius: borderRadius ?? Corners.s6Border,
          fontColor: textColor ?? Theme.of(context).colorScheme.onPrimary,
          fillColor: fillColor ?? Theme.of(context).colorScheme.primary,
          hoverColor:
              hoverColor ?? Theme.of(context).colorScheme.primaryContainer,
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
    Key? key,
    this.press,
    required this.size,
    this.borderRadius = BorderRadius.zero,
    this.borderColor = Colors.transparent,
    this.color = Colors.transparent,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TextButton(
        onPressed: press,
        style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(borderRadius: borderRadius))),
        child: child,
      ),
    );
  }
}
