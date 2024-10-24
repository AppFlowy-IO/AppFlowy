import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/ignore_parent_gesture.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class FlowyIconTextButton extends StatelessWidget {
  final Widget Function(bool onHover) textBuilder;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final void Function(bool)? onHover;
  final EdgeInsets? margin;
  final Widget Function(bool onHover)? leftIconBuilder;
  final Widget Function(bool onHover)? rightIconBuilder;
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
  final Color? borderColor;
  final bool resetHoverOnRebuild;

  const FlowyIconTextButton({
    super.key,
    required this.textBuilder,
    this.onTap,
    this.onSecondaryTap,
    this.onHover,
    this.margin,
    this.leftIconBuilder,
    this.rightIconBuilder,
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
    this.borderColor,
    this.resetHoverOnRebuild = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = hoverColor ?? Theme.of(context).colorScheme.secondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disable ? null : onTap,
      onSecondaryTap: disable ? null : onSecondaryTap,
      child: FlowyHover(
        resetHoverOnRebuild: resetHoverOnRebuild,
        cursor:
            disable ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        style: HoverStyle(
          borderRadius: radius ?? Corners.s6Border,
          hoverColor: color,
          borderColor: borderColor ?? Colors.transparent,
        ),
        onHover: disable ? null : onHover,
        isSelected: () => isSelected,
        builder: (context, onHover) => _render(context, onHover),
      ),
    );
  }

  Widget _render(BuildContext context, bool onHover) {
    final List<Widget> children = [];

    if (leftIconBuilder != null) {
      children.add(
        SizedBox.fromSize(
          size: leftIconSize,
          child: leftIconBuilder!(onHover),
        ),
      );
      children.add(HSpace(iconPadding));
    }

    if (expandText) {
      children.add(Expanded(child: textBuilder(onHover)));
    } else {
      children.add(textBuilder(onHover));
    }

    if (rightIconBuilder != null) {
      children.add(HSpace(iconPadding));
      // No need to define the size of rightIcon. Just use its intrinsic width
      children.add(rightIconBuilder!(onHover));
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
                color: borderColor ??
                    Theme.of(context).colorScheme.surfaceContainerHighest,
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

class FlowyButton extends StatelessWidget {
  final Widget text;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final void Function(bool)? onHover;
  final EdgeInsetsGeometry? margin;
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
  final Color? borderColor;
  final Color? backgroundColor;
  final bool resetHoverOnRebuild;

  const FlowyButton({
    super.key,
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
    this.borderColor,
    this.backgroundColor,
    this.resetHoverOnRebuild = true,
  });

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
        resetHoverOnRebuild: resetHoverOnRebuild,
        cursor:
            disable ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        style: HoverStyle(
          borderRadius: radius ?? Corners.s6Border,
          hoverColor: color,
          borderColor: borderColor ?? Colors.transparent,
          backgroundColor: backgroundColor ?? Colors.transparent,
        ),
        onHover: disable ? null : onHover,
        isSelected: () => isSelected,
        builder: (context, onHover) => _render(context),
      ),
    );
  }

  Widget _render(BuildContext context) {
    final List<Widget> children = [];

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
      children.add(HSpace(iconPadding));
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

    var decoration = this.decoration;

    if (decoration == null &&
        (showDefaultBoxDecorationOnMobile &&
            (Platform.isIOS || Platform.isAndroid))) {
      decoration = BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      );
    }

    if (decoration == null && (Platform.isIOS || Platform.isAndroid)) {
      if (showDefaultBoxDecorationOnMobile) {
        decoration = BoxDecoration(
          border: Border.all(
            color: borderColor ?? Theme.of(context).colorScheme.outline,
            width: 1.0,
          ),
          borderRadius: radius,
        );
      } else if (backgroundColor != null) {
        decoration = BoxDecoration(
          color: backgroundColor,
          borderRadius: radius,
        );
      }
    }

    return Container(
      decoration: decoration,
      child: Padding(
        padding: margin ??
            const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
        child: child,
      ),
    );
  }
}

class FlowyTextButton extends StatelessWidget {
  const FlowyTextButton(
    this.text, {
    super.key,
    this.onPressed,
    this.fontSize,
    this.fontColor,
    this.fontHoverColor,
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
    this.isDangerous = false,
    this.borderColor,
    this.lineHeight,
  });

  factory FlowyTextButton.primary({
    required BuildContext context,
    required String text,
    VoidCallback? onPressed,
  }) =>
      FlowyTextButton(
        text,
        constraints: const BoxConstraints(minHeight: 32),
        fillColor: Theme.of(context).colorScheme.primary,
        hoverColor: const Color(0xFF005483),
        fontColor: Theme.of(context).colorScheme.onPrimary,
        fontHoverColor: Colors.white,
        onPressed: onPressed,
      );

  factory FlowyTextButton.secondary({
    required BuildContext context,
    required String text,
    VoidCallback? onPressed,
  }) =>
      FlowyTextButton(
        text,
        constraints: const BoxConstraints(minHeight: 32),
        fillColor: Colors.transparent,
        hoverColor: Theme.of(context).colorScheme.primary,
        fontColor: Theme.of(context).colorScheme.primary,
        borderColor: Theme.of(context).colorScheme.primary,
        fontHoverColor: Colors.white,
        onPressed: onPressed,
      );

  final String text;
  final FontWeight? fontWeight;
  final Color? fontColor;
  final Color? fontHoverColor;
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
  final bool isDangerous;
  final Color? borderColor;
  final double? lineHeight;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (heading != null) {
      children.add(heading!);
      children.add(const HSpace(8));
    }
    children.add(Text(
      text,
      overflow: overflow,
      textAlign: TextAlign.center,
    ));

    Widget child = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: mainAxisAlignment,
      children: children,
    );

    child = ConstrainedBox(
      constraints: constraints,
      child: TextButton(
        onPressed: onPressed,
        focusNode: FocusNode(skipTraversal: onPressed == null),
        style: ButtonStyle(
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: WidgetStateProperty.all(padding),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              side: BorderSide(
                color: borderColor ??
                    (isDangerous
                        ? Theme.of(context).colorScheme.error
                        : Colors.transparent),
              ),
              borderRadius: radius ?? Corners.s6Border,
            ),
          ),
          textStyle: WidgetStateProperty.all(
            Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: fontWeight ?? FontWeight.w500,
                  fontSize: fontSize,
                  color: fontColor ?? Theme.of(context).colorScheme.onPrimary,
                  decoration: decoration,
                  fontFamily: fontFamily,
                  height: lineHeight ?? 1.1,
                ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.hovered)) {
                return hoverColor ??
                    (isDangerous
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.secondary);
              }

              return fillColor ??
                  (isDangerous
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.secondaryContainer);
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.hovered)) {
                return fontHoverColor ??
                    (fontColor ?? Theme.of(context).colorScheme.onSurface);
              }

              return fontColor ?? Theme.of(context).colorScheme.onSurface;
            },
          ),
        ),
        child: child,
      ),
    );

    if (tooltip != null) {
      child = FlowyTooltip(message: tooltip!, child: child);
    }

    if (onPressed == null) {
      child = ExcludeFocus(child: child);
    }

    return child;
  }
}

class FlowyRichTextButton extends StatelessWidget {
  const FlowyRichTextButton(
    this.text, {
    super.key,
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
  });

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

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (heading != null) {
      children.add(heading!);
      children.add(const HSpace(6));
    }
    children.add(
      RichText(text: text, overflow: overflow, textAlign: TextAlign.center),
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

    child = IgnoreParentGestureWidget(onPress: onPressed, child: child);

    if (tooltip != null) {
      child = FlowyTooltip(message: tooltip!, child: child);
    }

    return child;
  }
}
