import 'package:flutter/material.dart';

class StyleCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const StyleCloseButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Icon(Icons.close));
  }
}
