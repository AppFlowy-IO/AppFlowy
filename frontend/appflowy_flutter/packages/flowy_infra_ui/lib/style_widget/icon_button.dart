import 'dart:math';

import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

class FlowyIconButton extends StatelessWidget {
  final double width;
  final double? height;
  final Widget icon;
  final VoidCallback? onPressed;
  final Color? fillColor;
  final Color? hoverColor;
  final Color? iconColorOnHover;
  final EdgeInsets iconPadding;
  final BorderRadius? radius;
  final String? tooltipText;
  final InlineSpan? richTooltipText;
  final bool preferBelow;

  const FlowyIconButton({
    Key? key,
    this.width = 30,
    this.height,
    this.onPressed,
    this.fillColor = Colors.transparent,
    this.hoverColor,
    this.iconColorOnHover,
    this.iconPadding = EdgeInsets.zero,
    this.radius,
    this.tooltipText,
    this.richTooltipText,
    this.preferBelow = true,
    required this.icon,
  })  : assert((richTooltipText != null && tooltipText == null) ||
            (richTooltipText == null && tooltipText != null) ||
            (richTooltipText == null && tooltipText == null)),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child = icon;
    final size = Size(width, height ?? width);

    final tooltipMessage =
        tooltipText == null && richTooltipText == null ? '' : tooltipText;

    assert(size.width > iconPadding.horizontal);
    assert(size.height > iconPadding.vertical);

    final childWidth = min(size.width - iconPadding.horizontal,
        size.height - iconPadding.vertical);
    final childSize = Size(childWidth, childWidth);

    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(
        width: size.width,
        height: size.height,
      ),
      child: Tooltip(
        preferBelow: preferBelow,
        message: tooltipMessage,
        richMessage: richTooltipText,
        showDuration: Duration.zero,
        child: RawMaterialButton(
          visualDensity: VisualDensity.compact,
          hoverElevation: 0,
          highlightElevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: radius ?? Corners.s6Border),
          fillColor: fillColor,
          hoverColor: hoverColor ?? Theme.of(context).colorScheme.secondary,
          focusColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          elevation: 0,
          onPressed: onPressed,
          child: FlowyHover(
            style: HoverStyle(
              hoverColor: hoverColor,
              foregroundColorOnHover:
                  iconColorOnHover ?? Theme.of(context).iconTheme.color,
              backgroundColor: Colors.transparent,
            ),
            child: Padding(
              padding: iconPadding,
              child: SizedBox.fromSize(size: childSize, child: child),
            ),
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
      icon: svgWidget("home/drop_down_show"),
    );
  }
}
