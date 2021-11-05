import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class FlowyButton extends StatelessWidget {
  final Widget text;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Widget? icon;
  final Color hoverColor;
  const FlowyButton({
    Key? key,
    required this.text,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
    this.icon,
    this.hoverColor = Colors.transparent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: FlowyHover(
        config: HoverDisplayConfig(borderRadius: Corners.s6Border, hoverColor: hoverColor),
        builder: (context, onHover) => _render(),
      ),
    );
  }

  Widget _render() {
    List<Widget> children = List.empty(growable: true);

    if (icon != null) {
      children.add(SizedBox.fromSize(size: const Size.square(16), child: icon!));
      children.add(const HSpace(6));
    }

    children.add(Align(child: text));

    return Padding(
      padding: padding,
      child: Row(
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

    return RawMaterialButton(
      visualDensity: VisualDensity.compact,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius ?? BorderRadius.circular(2)),
      fillColor: fillColor,
      hoverColor: hoverColor ?? Colors.transparent,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      elevation: 0,
      onPressed: onPressed,
      child: child,
    );

    // if (hoverColor != null) {
    //   return InkWell(
    //     onTap: onPressed,
    //     child: FlowyHover(
    //       config: HoverDisplayConfig(borderRadius: radius ?? BorderRadius.circular(6), hoverColor: hoverColor!),
    //       builder: (context, onHover) => child,
    //     ),
    //   );
    // } else {
    //   return InkWell(
    //     onTap: onPressed,
    //     child: child,
    //   );
    // }
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
