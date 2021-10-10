import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

class FlowyIconButton extends StatelessWidget {
  final double width;
  final double? height;
  final Widget icon;
  final VoidCallback? onPressed;

  const FlowyIconButton({
    Key? key,
    this.height,
    this.onPressed,
    this.width = 30,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? width,
      child: IconButton(
        icon: icon,
        padding: EdgeInsets.zero,
        iconSize: width,
        alignment: Alignment.center,
        onPressed: onPressed,
      ),
    );
  }
}

class FlowyDropdownButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const FlowyDropdownButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: 16,
      onPressed: onPressed,
      icon: svg("home/drop_down_show"),
    );
  }
}

class ViewAddButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const ViewAddButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: 16,
      onPressed: onPressed,
      icon: svg("home/add"),
    );
  }
}

class ViewMoreButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const ViewMoreButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: 16,
      onPressed: onPressed,
      icon: svg("editor/details"),
    );
  }
}
