import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class ContinueWithPassword extends StatelessWidget {
  const ContinueWithPassword({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AFOutlinedTextButton.normal(
      text: 'Continue with password',
      size: AFButtonSize.l,
      alignment: Alignment.center,
      onTap: onTap,
    );
  }
}
