import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';

class FlowyImageIcon extends StatelessWidget {
  final AssetImage image;
  final Color? color;
  final double? size;

  const FlowyImageIcon(this.image, {super.key, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    return ImageIcon(image,
        size: size ?? Sizes.iconMed, color: color ?? Colors.white);
  }
}
