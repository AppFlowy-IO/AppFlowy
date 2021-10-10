import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

class FlowyIconButton extends StatelessWidget {
  final double width;
  final double? height;
  final double iconRatio;
  final Widget icon;
  final VoidCallback? onPressed;

  const FlowyIconButton({
    Key? key,
    this.height,
    this.onPressed,
    this.width = 30,
    required this.icon,
    this.iconRatio = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? width,
      child: IconButton(
        icon: icon,
        padding: EdgeInsets.zero,
        iconSize: width * iconRatio,
        alignment: Alignment.center,
        onPressed: onPressed,
      ),
    );
  }
}

class ViewMoreButton extends StatelessWidget {
  final double width;
  final double? height;
  final VoidCallback? onPressed;

  const ViewMoreButton({
    Key? key,
    this.height,
    this.onPressed,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: width,
      height: height,
      icon: svg("editor/details"),
      onPressed: onPressed,
    );
  }
}
