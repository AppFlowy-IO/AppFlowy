import 'package:flutter/material.dart';

class StyledMore extends StatelessWidget {
  final double width;
  final double? height;
  final VoidCallback? onPressed;

  const StyledMore({
    Key? key,
    required this.width,
    this.height,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? width,
      child: IconButton(
        icon: const Icon(Icons.more_vert),
        padding: EdgeInsets.zero,
        iconSize: width / 2,
        alignment: Alignment.center,
        onPressed: onPressed,
      ),
    );
  }
}
