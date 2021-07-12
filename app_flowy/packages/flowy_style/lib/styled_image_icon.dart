import 'package:flowy_style/size.dart';
import 'package:flutter/material.dart';

class StyledImageIcon extends StatelessWidget {
  final AssetImage image;
  final Color? color;
  final double? size;

  const StyledImageIcon(this.image, {Key? key, this.color, this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ImageIcon(image,
        size: size ?? Sizes.iconMed, color: color ?? Colors.white);
  }
}
