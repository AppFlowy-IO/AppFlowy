import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class MobileLogoutButton extends StatelessWidget {
  const MobileLogoutButton({
    super.key,
    this.icon,
    required this.text,
    this.textColor,
    required this.onPressed,
  });

  final FlowySvgData? icon;
  final String text;
  final Color? textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AFOutlinedIconTextButton.normal(
      text: text,
      onTap: onPressed,
      size: AFButtonSize.l,
      iconBuilder: (context, isHovering, disabled) {
        if (icon == null) {
          return const SizedBox.shrink();
        }
        return FlowySvg(
          icon!,
          size: Size.square(18),
        );
      },
    );
  }
}
