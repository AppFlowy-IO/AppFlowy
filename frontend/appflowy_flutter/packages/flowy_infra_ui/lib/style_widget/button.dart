import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!disable) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onSecondaryTap: onSecondaryTap,
        child: FlowyHover(
          style: HoverStyle(
            borderRadius: radius ?? Corners.s6Border,
            hoverColor: hoverColor ?? Theme.of(context).colorScheme.secondary,
          ),
          onHover: onHover,
          isSelected: () => isSelected,
          builder: (context, onHover) => _render(),
        ),
      );
    } else {
      return Opacity(
        opacity: disableOpacity,
        child: MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: _render(),
        ),
      );
    }
  }

  Widget _render() {
    List<Widget> children = List.empty(growable: true);

    if (leftIcon != null) {
      children.add(
        SizedBox.fromSize(
          size: leftIconSize,
          child: leftIcon!,
        ),
      );
      children.add(const HSpace(6));
    }

    children.add(Expanded(child: text));

    if (rightIcon != null) {
      children.add(const HSpace(6));
      // No need to define the size of rightIcon. Just use its intrinsic width
      children.add(rightIcon!);
    }

    Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );

    if (useIntrinsicWidth) {
      child = IntrinsicWidth(child: child);
    }

    return Container(
      decoration: decoration,
      child: Padding(
        padding:
            margin ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
    this.constraints = const BoxConstraints(minWidth: 58.0, minHeight: 30.0),
    this.decoration,
    this.fontFamily,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (heading != null) {
      children.add(heading!);
      children.add(const HSpace(6));
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
      hoverColor:
          hoverColor ?? Theme.of(context).colorScheme.secondaryContainer,
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
      child = Tooltip(
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
      child = Tooltip(
        message: tooltip!,
        child: child,
      );
    }

    return child;
  }
}
