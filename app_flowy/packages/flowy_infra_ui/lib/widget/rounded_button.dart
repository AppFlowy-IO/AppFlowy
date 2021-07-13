import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final VoidCallback? press;
  final String? title;
  final Size? size;

  const RoundedButton({
    Key? key,
    this.press,
    this.title,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 100,
        maxWidth: size?.width ?? double.infinity,
        minHeight: 50,
        maxHeight: size?.height ?? double.infinity,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: TextButton(
          child: Text(title ?? ''),
          onPressed: press,
        ),
      ),
    );
  }
}
