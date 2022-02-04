import 'dart:math';

import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FlowyIconButton extends StatelessWidget {
  final double width;
  final double? height;
  final Widget icon;
  final VoidCallback? onPressed;
  final Color? fillColor;
  final Color? hoverColor;
  final EdgeInsets iconPadding;
  final BorderRadius? radius;
  final String? tooltipText;

  const FlowyIconButton({
    Key? key,
    this.width = 30,
    this.height,
    this.onPressed,
    this.fillColor = Colors.transparent,
    this.hoverColor = Colors.transparent,
    this.iconPadding = EdgeInsets.zero,
    this.radius,
    this.tooltipText,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child = icon;
    final size = Size(width, height ?? width);

    assert(size.width > iconPadding.horizontal);
    assert(size.height > iconPadding.vertical);

    final childWidth = min(size.width - iconPadding.horizontal, size.height - iconPadding.vertical);
    final childSize = Size(childWidth, childWidth);

    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: size.width, height: size.height),
      child: Tooltip(
        message: tooltipText ?? '',
        showDuration: Duration.zero,
        child: RawMaterialButton(
          visualDensity: VisualDensity.compact,
          hoverElevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(borderRadius: radius ?? BorderRadius.circular(2)),
          fillColor: fillColor,
          hoverColor: hoverColor,
          focusColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          elevation: 0,
          onPressed: onPressed,
          child: Padding(
            padding: iconPadding,
            child: SizedBox.fromSize(child: child, size: childSize),
          ),
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
