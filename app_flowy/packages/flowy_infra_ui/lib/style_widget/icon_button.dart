import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

class FlowyIconButton extends StatelessWidget {
  final double width;
  final double? height;
  final Widget icon;
  final VoidCallback? onPressed;
  final Color? fillColor;
  final Color? hoverColor;
  final EdgeInsets iconPadding;

  const FlowyIconButton({
    Key? key,
    this.height,
    this.onPressed,
    this.width = 30,
    this.fillColor = Colors.transparent,
    this.hoverColor = Colors.transparent,
    this.iconPadding = EdgeInsets.zero,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child = icon;

    // if (onPressed == null) {
    //   child = ColorFiltered(
    //     colorFilter: ColorFilter.mode(
    //       Colors.grey,
    //       BlendMode.saturation,
    //     ),
    //     child: child,
    //   );
    // }

    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: width, height: width),
      child: RawMaterialButton(
        visualDensity: VisualDensity.compact,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        fillColor: fillColor,
        hoverColor: hoverColor,
        focusColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        elevation: 0,
        onPressed: onPressed,
        child: Padding(
          padding: iconPadding,
          child: SizedBox.fromSize(child: child, size: Size(width, width)),
        ),
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
