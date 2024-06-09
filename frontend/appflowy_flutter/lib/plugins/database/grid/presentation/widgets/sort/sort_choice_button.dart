import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class SortChoiceButton extends StatelessWidget {
  const SortChoiceButton({
    super.key,
    required this.text,
    this.onTap,
    this.radius = const Radius.circular(14),
    this.leftIcon,
    this.rightIcon,
    this.editable = true,
  });

  final String text;
  final VoidCallback? onTap;
  final Radius radius;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.fromBorderSide(
          BorderSide(color: Theme.of(context).dividerColor),
        ),
        borderRadius: BorderRadius.all(radius),
      ),
      useIntrinsicWidth: true,
      text: FlowyText(
        text,
        color: AFThemeExtension.of(context).textColor,
        overflow: TextOverflow.ellipsis,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      radius: BorderRadius.all(radius),
      leftIcon: leftIcon,
      rightIcon: rightIcon,
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      onTap: onTap,
      disable: !editable,
      disableOpacity: 1.0,
    );
  }
}
