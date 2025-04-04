import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class ContinueWithEmail extends StatelessWidget {
  const ContinueWithEmail({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AFFilledTextButton.primary(
      text: 'Continue with email',
      size: AFButtonSize.l,
      alignment: Alignment.center,
      onTap: onTap,
    );
  }
}
