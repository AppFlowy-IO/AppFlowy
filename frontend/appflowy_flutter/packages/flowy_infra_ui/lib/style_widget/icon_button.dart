import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_svg/flowy_svg.dart';

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
  final BoxDecoration? decoration;
  final bool? isSelected;

  const FlowyIconButton({
    super.key,
    this.width = 30,
    this.height,
    this.onPressed,
    this.fillColor = Colors.transparent,
    this.hoverColor,
    this.iconColorOnHover,
    this.iconPadding = EdgeInsets.zero,
    this.radius,
    this.decoration,
    this.tooltipText,
    this.richTooltipText,
    this.preferBelow = true,
    this.isSelected,
    required this.icon,
  }) : assert((richTooltipText != null && tooltipText == null) ||
            (richTooltipText == null && tooltipText != null) ||
            (richTooltipText == null && tooltipText == null));

  @override
  Widget build(BuildContext context) {
    Widget child = icon;
    final size = Size(width, height ?? width);

    final tooltipMessage =
        tooltipText == null && richTooltipText == null ? '' : tooltipText;

    assert(size.width > iconPadding.horizontal);
    assert(size.height > iconPadding.vertical);

    child = Padding(
      padding: iconPadding,
      child: Center(child: child),
    );

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      child = FlowyHover(
        isSelected: isSelected != null ? () => isSelected! : null,
        style: HoverStyle(
            hoverColor: hoverColor,
            foregroundColorOnHover:
                iconColorOnHover ?? Theme.of(context).iconTheme.color,
            borderRadius: radius ?? Corners.s6Border
            //Do not set background here. Use [fillColor] instead.
            ),
        resetHoverOnRebuild: false,
        child: child,
      );
    }

    return Container(
      constraints: BoxConstraints.tightFor(
        width: size.width,
        height: size.height,
      ),
      decoration: decoration,
      child: FlowyTooltip(
        preferBelow: preferBelow,
        message: tooltipMessage,
        richMessage: richTooltipText,
        child: RawMaterialButton(
          clipBehavior: Clip.antiAlias,
          visualDensity: VisualDensity.compact,
          hoverElevation: 0,
          highlightElevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: radius ?? Corners.s6Border),
          fillColor: fillColor,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          elevation: 0,
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}

class FlowyDropdownButton extends StatelessWidget {
  const FlowyDropdownButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: 16,
      onPressed: onPressed,
      icon: const FlowySvg(FlowySvgData("home/drop_down_show")),
    );
  }
}
