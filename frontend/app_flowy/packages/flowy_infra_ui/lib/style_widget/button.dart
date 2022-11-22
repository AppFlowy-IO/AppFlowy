import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

class FlowyButton extends StatelessWidget {
  final Widget text;
  final VoidCallback? onTap;
  final void Function(bool)? onHover;
  final EdgeInsets margin;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final Color? hoverColor;
  final bool isSelected;
  final BorderRadius radius;
  final BoxDecoration? decoration;

  const FlowyButton({
    Key? key,
    required this.text,
    this.onTap,
    this.onHover,
    this.margin = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.leftIcon,
    this.rightIcon,
    this.hoverColor,
    this.isSelected = false,
    this.radius = const BorderRadius.all(Radius.circular(6)),
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: FlowyHover(
        style: HoverStyle(
          borderRadius: radius,
          hoverColor: hoverColor ?? Theme.of(context).colorScheme.secondary,
        ),
        onHover: onHover,
        isSelected: () => isSelected,
        builder: (context, onHover) => _render(),
      ),
    );
  }

  Widget _render() {
    List<Widget> children = List.empty(growable: true);

    if (leftIcon != null) {
      children.add(
          SizedBox.fromSize(size: const Size.square(16), child: leftIcon!));
      children.add(const HSpace(6));
    }

    children.add(Expanded(child: text));

    if (rightIcon != null) {
      children.add(
          SizedBox.fromSize(size: const Size.square(16), child: rightIcon!));
    }

    return Container(
      decoration: decoration,
      child: Padding(
        padding: margin,
        child: IntrinsicWidth(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }
}

class FlowyTextButton extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextOverflow overflow;
  final FontWeight fontWeight;

  final VoidCallback? onPressed;
  final EdgeInsets padding;
  final Widget? heading;
  final Color? hoverColor;
  final Color? fillColor;
  final Color? textColor;
  final BorderRadius? radius;
  final MainAxisAlignment mainAxisAlignment;
  final String? tooltip;
  final BoxConstraints constraints;

  // final HoverDisplayConfig? hoverDisplay;
  const FlowyTextButton(
    this.text, {
    Key? key,
    this.onPressed,
    this.fontSize = 16,
    this.overflow = TextOverflow.ellipsis,
    this.fontWeight = FontWeight.w400,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.hoverColor,
    this.fillColor,
    this.textColor,
    this.heading,
    this.radius,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.tooltip,
    this.constraints = const BoxConstraints(minWidth: 58.0, minHeight: 30.0),
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
        color: textColor,
        overflow: overflow,
        fontWeight: fontWeight,
        fontSize: fontSize,
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
      shape: RoundedRectangleBorder(
        borderRadius: radius ?? BorderRadius.circular(2),
      ),
      fillColor: fillColor,
      hoverColor: hoverColor ?? Theme.of(context).colorScheme.secondary,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      elevation: 0,
      constraints: constraints,
      onPressed: onPressed,
      child: child,
    );

    if (tooltip != null) {
      child = Tooltip(
        message: tooltip!,
        textStyle: TextStyles.caption.textColor(Colors.white),
        child: child,
      );
    }

    return child;
  }
}
