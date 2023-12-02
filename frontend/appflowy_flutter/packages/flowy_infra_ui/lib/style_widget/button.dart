import 'dart:io';

import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/ignore_parent_gesture.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class FlowyButton extends StatelessWidget {
  final Widget text;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final void Function(bool)? onHover;
  final EdgeInsets? margin;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final Color? hoverColor;
  final bool isSelected;
  final BorderRadius? radius;
  final BoxDecoration? decoration;
  final bool useIntrinsicWidth;
  final bool disable;
  final double disableOpacity;
  final Size? leftIconSize;
  final bool expandText;
  final MainAxisAlignment mainAxisAlignment;
  final bool showDefaultBoxDecorationOnMobile;
  final double iconPadding;
  final bool expand;

  const FlowyButton({
    Key? key,
    required this.text,
    this.onTap,
    this.onSecondaryTap,
    this.onHover,
    this.margin,
    this.leftIcon,
    this.rightIcon,
    this.hoverColor,
    this.isSelected = false,
    this.radius,
    this.decoration,
    this.useIntrinsicWidth = false,
    this.disable = false,
    this.disableOpacity = 0.5,
    this.leftIconSize = const Size.square(16),
    this.expandText = true,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.showDefaultBoxDecorationOnMobile = false,
    this.iconPadding = 6,
    this.expand = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = hoverColor ?? Theme.of(context).colorScheme.secondary;
    final alpha = (255 * disableOpacity).toInt();
    color.withAlpha(alpha);

    if (Platform.isIOS || Platform.isAndroid) {
      return InkWell(
        onTap: disable ? null : onTap,
        onSecondaryTap: disable ? null : onSecondaryTap,
        borderRadius: radius ?? Corners.s6Border,
        child: _render(context),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disable ? null : onTap,
      onSecondaryTap: disable ? null : onSecondaryTap,
      child: FlowyHover(
        cursor:
            disable ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        style: HoverStyle(
          borderRadius: radius ?? Corners.s6Border,
          hoverColor: color,
        ),
        onHover: disable ? null : onHover,
        isSelected: () => isSelected,
        builder: (context, onHover) => _render(context),
      ),
    );
  }

  Widget _render(BuildContext context) {
    List<Widget> children = List.empty(growable: true);

    if (leftIcon != null) {
      children.add(
        SizedBox.fromSize(
          size: leftIconSize,
          child: leftIcon!,
        ),
      );
      children.add(HSpace(iconPadding));
    }

    if (expandText) {
      children.add(Expanded(child: text));
    } else {
      children.add(text);
    }

    if (rightIcon != null) {
      children.add(const HSpace(6));
      // No need to define the size of rightIcon. Just use its intrinsic width
      children.add(rightIcon!);
    }

    Widget child = Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: children,
    );

    if (useIntrinsicWidth) {
      child = IntrinsicWidth(child: child);
    }

    final decoration = this.decoration ??
        (showDefaultBoxDecorationOnMobile &&
                (Platform.isIOS || Platform.isAndroid)
            ? BoxDecoration(
                border: Border.all(
                color: Theme.of(context).colorScheme.surfaceVariant,
                width: 1.0,
              ))
            : null);

    return Container(
      decoration: decoration,
      child: Padding(
        padding:
            margin ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: child,
      ),
    );
  }
}

class FlowyTextButton extends StatelessWidget {
  final String text;
  final FontWeight? fontWeight;
  final Color? fontColor;
  final double? fontSize;
  final TextOverflow overflow;

  final VoidCallback? onPressed;
  final EdgeInsets padding;
  final Widget? heading;
  final Color? hoverColor;
  final Color? fillColor;
  final BorderRadius? radius;
  final MainAxisAlignment mainAxisAlignment;
  final String? tooltip;
  final BoxConstraints constraints;

  final TextDecoration? decoration;

  final String? fontFamily;

  // final HoverDisplayConfig? hoverDisplay;
  const FlowyTextButton(
    this.text, {
    Key? key,
    this.onPressed,
    this.fontSize,
    this.fontColor,
    this.overflow = TextOverflow.ellipsis,
    this.fontWeight,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.hoverColor,
    this.fillColor,
    this.heading,
    this.radius,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.tooltip,
    this.constraints = const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
    this.decoration,
    this.fontFamily,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (heading != null) {
      children.add(heading!);
      children.add(const HSpace(8));
    }
    children.add(
      FlowyText(
        text,
        overflow: overflow,
        fontWeight: fontWeight,
        fontSize: fontSize,
        color: fontColor,
        textAlign: TextAlign.center,
        decoration: decoration,
        fontFamily: fontFamily,
      ),
    );

    Widget child = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: mainAxisAlignment,
      children: children,
    );

    child = RawMaterialButton(
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius ?? Corners.s6Border),
      fillColor: fillColor ?? Theme.of(context).colorScheme.secondaryContainer,
      hoverColor:
          hoverColor ?? Theme.of(context).colorScheme.secondaryContainer,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      elevation: 0,
      constraints: constraints,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: padding,
      onPressed: onPressed,
      child: child,
    );

    if (tooltip != null) {
      child = FlowyTooltip(
        message: tooltip!,
        child: child,
      );
    }

    return child;
  }
}

class FlowyRichTextButton extends StatelessWidget {
  final InlineSpan text;
  final TextOverflow overflow;

  final VoidCallback? onPressed;
  final EdgeInsets padding;
  final Widget? heading;
  final Color? hoverColor;
  final Color? fillColor;
  final BorderRadius? radius;
  final MainAxisAlignment mainAxisAlignment;
  final String? tooltip;
  final BoxConstraints constraints;

  final TextDecoration? decoration;

  // final HoverDisplayConfig? hoverDisplay;
  const FlowyRichTextButton(
    this.text, {
    Key? key,
    this.onPressed,
    this.overflow = TextOverflow.ellipsis,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.hoverColor,
    this.fillColor,
    this.heading,
    this.radius,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.tooltip,
    this.constraints = const BoxConstraints(minWidth: 58.0, minHeight: 30.0),
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (heading != null) {
      children.add(heading!);
      children.add(const HSpace(6));
    }
    children.add(
      RichText(
        text: text,
        overflow: overflow,
        textAlign: TextAlign.center,
      ),
    );

    Widget child = Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: mainAxisAlignment,
        children: children,
      ),
    );

    child = RawMaterialButton(
      visualDensity: VisualDensity.compact,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius ?? Corners.s6Border),
      fillColor: fillColor ?? Theme.of(context).colorScheme.secondaryContainer,
      hoverColor: hoverColor ?? Theme.of(context).colorScheme.secondary,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      elevation: 0,
      constraints: constraints,
      onPressed: () {},
      child: child,
    );

    child = IgnoreParentGestureWidget(
      onPress: onPressed,
      child: child,
    );

    if (tooltip != null) {
      child = FlowyTooltip(
        message: tooltip!,
        child: child,
      );
    }

    return child;
  }
}
