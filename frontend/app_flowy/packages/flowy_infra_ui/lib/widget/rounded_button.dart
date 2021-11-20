import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';

class RoundedTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? title;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final Color borderColor;
  final Color color;
  final Color textColor;
  final double fontSize;

  const RoundedTextButton({
    Key? key,
    this.onPressed,
    this.title,
    this.width,
    this.height,
    this.borderRadius = Corners.s12Border,
    this.borderColor = Colors.transparent,
    this.color = Colors.transparent,
    this.textColor = Colors.white,
    this.fontSize = 16,
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
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: borderRadius,
          color: color,
        ),
        child: SizedBox.expand(
          child: TextButton(
            child: Text(
              title ?? '',
              style: TextStyle(color: textColor, fontSize: fontSize),
            ),
            onPressed: onPressed,
          ),
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
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
          borderRadius: borderRadius,
        ))),
        child: child,
      ),
    );
  }
}
