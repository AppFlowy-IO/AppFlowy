import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class SortChoiceButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final Radius radius;

  const SortChoiceButton({
    required this.text,
    this.onTap,
    this.radius = const Radius.circular(14),
    this.leftIcon,
    this.rightIcon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(
      color: AFThemeExtension.of(context).toggleOffFill,
      width: 1.0,
    );

    final decoration = BoxDecoration(
      color: Colors.transparent,
      border: Border.fromBorderSide(borderSide),
      borderRadius: const BorderRadius.all(Radius.circular(14)),
    );

    return FlowyButton(
      decoration: decoration,
      useIntrinsicWidth: true,
      text: FlowyText(text),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      radius: BorderRadius.all(radius),
      leftIcon: leftIcon,
      rightIcon: rightIcon,
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      onTap: onTap,
    );
  }
}
