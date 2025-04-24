import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class MobileLogoutButton extends StatelessWidget {
  const MobileLogoutButton({
    super.key,
    required this.text,
    this.textColor,
    required this.onPressed,
  });

  final String text;
  final Color? textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AFOutlinedTextButton.normal(
      alignment: Alignment.center,
      text: text,
      onTap: onPressed,
      size: AFButtonSize.l,
    );
  }
}
