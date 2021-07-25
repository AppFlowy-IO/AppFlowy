import 'package:flutter/material.dart';

class RoundedTextButton extends StatelessWidget {
  final VoidCallback? press;
  final String? title;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final Color borderColor;
  final Color color;
  final Color textColor;

  const RoundedTextButton({
    Key? key,
    this.press,
    this.title,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.borderColor = Colors.transparent,
    this.color = Colors.transparent,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 100,
        maxWidth: width ?? double.infinity,
        minHeight: 50,
        maxHeight: height ?? 60,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: borderRadius,
          color: color,
        ),
        child: SizedBox.expand(
          child: TextButton(
            child: Text(title ?? '', style: TextStyle(color: textColor)),
            onPressed: press,
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
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
          borderRadius: borderRadius,
        ))),
        child: child,
      ),
    );
  }
}
