import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class FlowyButton extends StatelessWidget {
  final Widget text;
  final VoidCallback? onTap;
  final void Function(bool)? onHover;
  final EdgeInsets margin;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final Color hoverColor;
  final bool isSelected;
  final BorderRadius radius;

  const FlowyButton({
    Key? key,
    required this.text,
    this.onTap,
    this.onHover,
    this.margin = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.leftIcon,
    this.rightIcon,
    this.hoverColor = Colors.transparent,
    this.isSelected = false,
    this.radius = const BorderRadius.all(Radius.circular(6)),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: FlowyHover(
        style: HoverStyle(
          borderRadius: radius,
          hoverColor: hoverColor,
        ),
        onHover: onHover,
        setSelected: () => isSelected,
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

    return Padding(
      padding: margin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
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
  final BorderRadius? radius;
  final MainAxisAlignment mainAxisAlignment;
  final String? tooltip;

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
    this.heading,
    this.radius,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.tooltip,
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
          borderRadius: radius ?? BorderRadius.circular(2)),
      fillColor: fillColor,
      hoverColor: hoverColor ?? Colors.transparent,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      elevation: 0,
      onPressed: onPressed,
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
// return TextButton(
//   style: ButtonStyle(
//     textStyle: MaterialStateProperty.all(TextStyle(fontSize: fontSize)),
//     alignment: Alignment.centerLeft,
//     foregroundColor: MaterialStateProperty.all(Colors.black),
//     padding: MaterialStateProperty.all<EdgeInsets>(
//         const EdgeInsets.symmetric(horizontal: 2)),
//   ),
//   onPressed: onPressed,
//   child: Text(
//     text,
//     overflow: TextOverflow.ellipsis,
//     softWrap: false,
//   ),
// );
